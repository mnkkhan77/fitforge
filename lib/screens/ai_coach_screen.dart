import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// ─── Data models ──────────────────────────────────────────────────────────────

class ChatMsg {
  final String text;
  final bool isUser;
  final bool isError;
  final List<String> followups;
  const ChatMsg({required this.text, required this.isUser, this.isError = false, this.followups = const []});

  Map<String, dynamic> toJson() => {
    'text': text, 'isUser': isUser, 'isError': isError, 'followups': followups,
  };
  factory ChatMsg.fromJson(Map<String, dynamic> j) => ChatMsg(
    text: j['text'] as String,
    isUser: j['isUser'] as bool,
    isError: (j['isError'] as bool?) ?? false,
    followups: (j['followups'] as List?)?.cast<String>() ?? [],
  );
}

class ChatSession {
  final String id;
  String title;
  final DateTime createdAt;
  final List<ChatMsg> messages;

  ChatSession({required this.id, required this.title, required this.createdAt, required this.messages});

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title,
    'createdAt': createdAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
  };
  factory ChatSession.fromJson(Map<String, dynamic> j) => ChatSession(
    id: j['id'] as String,
    title: j['title'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    messages: (j['messages'] as List).map((m) => ChatMsg.fromJson(Map<String, dynamic>.from(m))).toList(),
  );
}

// ─── Constants ────────────────────────────────────────────────────────────────

const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
const _model = 'llama-3.3-70b-versatile';
const _fallbackSuggestions = [
  'What should I focus on today?',
  "I'm feeling sore — should I rest?",
  'Suggest a high-protein Indian meal',
  'How do I build strength faster?',
  'Analyze my progress this week',
];

// ─── Main screen ──────────────────────────────────────────────────────────────

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});
  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _inputCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _loading = false;
  bool _keySet = false;
  String _apiKey = '';
  bool _showKey = false;

  List<ChatSession> _sessions = [];
  String _currentId = '';

  List<String> _suggestions = _fallbackSuggestions;
  bool _loadingSuggestions = false;

  // ── Convenience getters ─────────────────────────────────────────────────────

  ChatSession? get _current => _sessions.isEmpty
      ? null
      : _sessions.firstWhere((s) => s.id == _currentId, orElse: () => _sessions.last);

  List<ChatMsg> get _msgs => _current?.messages ?? [];

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _keyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadKey();
    await _loadSessions();
  }

  // ── Key management ──────────────────────────────────────────────────────────

  Future<void> _loadKey() async {
    String key = '';
    try {
      if (kOpenAiKey.isNotEmpty && kOpenAiKey != 'YOUR_KEY_HERE') {
        key = kOpenAiKey;
      } else {
        key = await _secureStorage.read(key: 'openai_key') ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() { _apiKey = key; _keySet = key.isNotEmpty; });
  }

  Future<void> _saveKey(String key) async {
    final k = key.trim();
    if (k.isEmpty) return;
    try {
      await _secureStorage.write(key: 'openai_key', value: k);
    } catch (_) {}
    if (mounted) setState(() { _apiKey = k; _keySet = true; });
    await _loadSessions();
  }

  Future<void> _clearKey() async {
    try {
      await _secureStorage.delete(key: 'openai_key');
    } catch (_) {}
    if (mounted) setState(() { _apiKey = ''; _keySet = false; _keyCtrl.clear(); });
  }

  // ── Session persistence ──────────────────────────────────────────────────────

  Future<void> _loadSessions() async {
    List<ChatSession> loaded = [];
    String savedId = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ai_sessions');
      savedId = prefs.getString('ai_current_id') ?? '';
      if (raw != null) {
        loaded = (jsonDecode(raw) as List)
            .map((j) => ChatSession.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
      }
    } catch (_) {}

    if (loaded.isEmpty) loaded = [_newSession()];
    final resolvedId = loaded.any((s) => s.id == savedId) ? savedId : loaded.last.id;

    if (mounted) {
      setState(() { _sessions = loaded; _currentId = resolvedId; });
      if (_msgs.isEmpty && _keySet) _fetchSuggestions();
    }
  }

  Future<void> _saveSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ai_sessions', jsonEncode(_sessions.map((s) => s.toJson()).toList()));
      await prefs.setString('ai_current_id', _currentId);
    } catch (_) {}
  }

  ChatSession _newSession() => ChatSession(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: 'New Chat',
    createdAt: DateTime.now(),
    messages: [],
  );

  void _createNewSession() {
    final s = _newSession();
    setState(() { _sessions.add(s); _currentId = s.id; });
    _saveSessions();
    if (_keySet) _fetchSuggestions();
  }

  void _switchSession(String id) {
    setState(() => _currentId = id);
    _saveSessions();
    if (_msgs.isEmpty && _keySet) _fetchSuggestions();
    _scrollToBottom();
  }

  void _deleteSession(String id) {
    setState(() {
      _sessions.removeWhere((s) => s.id == id);
      if (_sessions.isEmpty) _sessions.add(_newSession());
      if (_currentId == id) _currentId = _sessions.last.id;
    });
    _saveSessions();
  }

  void _addMsg(ChatMsg msg) {
    final session = _current;
    if (session == null) return;
    setState(() {
      session.messages.add(msg);
      // Set title from first user message
      if (msg.isUser && session.title == 'New Chat') {
        session.title = msg.text.length > 40
            ? '${msg.text.substring(0, 40)}...'
            : msg.text;
      }
    });
    _saveSessions();
  }

  // ── Suggestions ──────────────────────────────────────────────────────────────

  Future<void> _fetchSuggestions() async {
    if (!mounted || !_keySet) return;
    final p = context.read<AppProvider>();
    const levels = ['Noob', 'Beginner', 'Intermediate', 'Advanced', 'Expert'];
    final level = levels[(p.userLevel - 1).clamp(0, 4)];

    setState(() => _loadingSuggestions = true);
    try {
      final res = await http.post(
        Uri.parse(_groqUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'model': _model,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': 'You are a fitness app assistant. Return ONLY valid JSON.'},
            {
              'role': 'user',
              'content': 'Give me 5 short questions (under 10 words each) that I as a user would ask my AI fitness coach, based on my profile: Level=$level, Goal=${p.selectedGoal}, Streak=${p.streak} days, Workouts=${p.totalWorkouts}, Weekly kcal burned=${p.weeklyCalsBurned}. These are questions FROM me TO the coach — asking for advice, tips, or analysis. Return JSON: {"questions":["q1","q2","q3","q4","q5"]}',
            },
          ],
          'max_tokens': 200,
          'temperature': 0.9,
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        final choices = body['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']?['content']?.toString() ?? '';
          if (content.isNotEmpty) {
            final parsed = jsonDecode(_cleanJson(content));
            final qs = (parsed['questions'] as List?)?.whereType<String>().toList() ?? [];
            if (qs.isNotEmpty && mounted) setState(() => _suggestions = qs);
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingSuggestions = false);
  }

  // ── System prompt ───────────────────────────────────────────────────────────

  String _sysPrompt(AppProvider p) {
    const levels = ['Noob', 'Beginner', 'Intermediate', 'Advanced', 'Expert'];
    final level = levels[(p.userLevel - 1).clamp(0, 4)];
    final plan = p.selectedPlanType == '5day' ? '5-Day Plan'
        : p.selectedPlanType == '7day' ? '7-Day Plan' : 'None selected';
    return '''You are FitForge AI Coach, a personal fitness and nutrition assistant.

User Profile:
- Fitness Level: $level
- Goal: ${p.selectedGoal}
- Current Streak: ${p.streak} days
- Total Workouts: ${p.totalWorkouts}
- Weekly Calories Burned: ${p.weeklyCalsBurned} kcal
- Active Diet Plan: ${p.activeDietPlan?.name ?? 'None'}
- Daily Calorie Goal: ${p.calorieGoal} kcal
- Calories Logged Today: ${p.todayCalIn} kcal
- Training Plan: $plan

Always respond with valid JSON in exactly this structure:
{"answer":"your response (max 150 words, personalized, use bullet points for steps)","followups":["question user asks next 1","question user asks next 2","question user asks next 3"]}

The "followups" are short questions (under 8 words) the USER would want to ask YOU next.''';
  }

  // ── Chat send ────────────────────────────────────────────────────────────────

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _loading) return;

    final p = context.read<AppProvider>();
    _addMsg(ChatMsg(text: trimmed, isUser: true));
    setState(() => _loading = true);
    _inputCtrl.clear();
    _scrollToBottom();

    final history = _msgs
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    try {
      final res = await http.post(
        Uri.parse(_groqUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'model': _model,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _sysPrompt(p)},
            ...history,
          ],
          'max_tokens': 400,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final choices = body['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          _addMsg(ChatMsg(text: '⚠️ Empty response from AI.', isUser: false, isError: true));
        } else {
          _parseAndAddReply(choices[0]['message']['content'].toString());
        }
      } else {
        String errMsg = 'API error ${res.statusCode}';
        try { errMsg = jsonDecode(res.body)['error']?['message'] ?? errMsg; } catch (_) {}
        _addMsg(ChatMsg(text: '⚠️ $errMsg', isUser: false, isError: true));
      }
    } on Exception catch (e) {
      final msg = e.toString().contains('TimeoutException')
          ? '⚠️ Request timed out. Try again.'
          : '⚠️ Could not connect. Check your internet or API key.';
      _addMsg(ChatMsg(text: msg, isUser: false, isError: true));
    }

    setState(() => _loading = false);
    _scrollToBottom();
  }

  void _parseAndAddReply(String raw) {
    try {
      final parsed = jsonDecode(_cleanJson(raw));
      final answer = (parsed['answer'] as String?)?.trim() ?? raw;
      final followups = (parsed['followups'] as List?)?.whereType<String>().toList() ?? [];
      _addMsg(ChatMsg(text: answer, isUser: false, followups: followups));
    } catch (_) {
      _addMsg(ChatMsg(text: raw.trim(), isUser: false));
    }
  }

  String _cleanJson(String raw) {
    var s = raw.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '').trim();
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start >= 0 && end > start) return s.substring(start, end + 1);
    return s;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_keySet) {
      return _KeySetup(ctrl: _keyCtrl, onSave: _saveKey, showKey: _showKey, onToggleShow: () => setState(() => _showKey = !_showKey));
    }

    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 14),
        color: bg,
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [indigo, Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🤖', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _current?.title == 'New Chat' ? 'AI COACH' : (_current?.title ?? 'AI COACH'),
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const Text('Llama 3.3 70B · context-aware', style: TextStyle(color: textMuted, fontSize: 10)),
            ]),
          ),
          // New chat
          GestureDetector(
            onTap: _createNewSession,
            child: Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: indigo.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: indigo.withValues(alpha: 0.4))),
              child: const Icon(Icons.add, color: indigoFaint, size: 18),
            ),
          ),
          // Sessions history
          GestureDetector(
            onTap: () => _showSessionsSheet(context),
            child: Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.history_rounded, color: textMuted, size: 18),
            ),
          ),
          // Key management
          GestureDetector(
            onTap: () => _showKeyDialog(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.key_outlined, color: textMuted, size: 16),
            ),
          ),
        ]),
      ),

      // Messages or empty state
      Expanded(
        child: _msgs.isEmpty
            ? _EmptyState(suggestions: _suggestions, loading: _loadingSuggestions, onTap: _send)
            : ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: _msgs.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _msgs.length) return const _TypingIndicator();
                  return _Bubble(msg: _msgs[i], onFollowup: _send);
                },
              ),
      ),

      // Input bar
      Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: bg, border: Border(top: BorderSide(color: surface2, width: 0.5))),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              style: const TextStyle(color: textPrimary, fontSize: 14),
              maxLines: 4, minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_loading,
              decoration: InputDecoration(
                hintText: 'Ask your coach anything...',
                hintStyle: const TextStyle(color: textMuted, fontSize: 13),
                filled: true, fillColor: surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: indigo, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _loading ? null : () => _send(_inputCtrl.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: _loading ? null : const LinearGradient(colors: [indigo, Color(0xFF8B5CF6)]),
                color: _loading ? surface2 : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_loading ? Icons.hourglass_empty_rounded : Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ── Dialogs / sheets ─────────────────────────────────────────────────────────

  void _showSessionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36, height: 4,
              decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                const Text('CHATS', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const Spacer(),
                GestureDetector(
                  onTap: () { Navigator.pop(ctx); _createNewSession(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [indigo, Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('New Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    ]),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: _sessions.length,
                itemBuilder: (_, i) {
                  final s = _sessions[_sessions.length - 1 - i]; // newest first
                  final isActive = s.id == _currentId;
                  return Dismissible(
                    key: Key(s.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete_outline, color: red),
                    ),
                    onDismissed: (_) {
                      _deleteSession(s.id);
                      if (_sessions.isEmpty) {
                        Navigator.pop(ctx);
                      } else {
                        setSheetState(() {});
                      }
                    },
                    child: GestureDetector(
                      onTap: () { Navigator.pop(ctx); _switchSession(s.id); },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isActive ? indigo.withValues(alpha: 0.15) : surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isActive ? indigo.withValues(alpha: 0.4) : surface2),
                        ),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: isActive ? indigo.withValues(alpha: 0.2) : bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(
                              s.messages.isEmpty ? '💬' : '🤖',
                              style: const TextStyle(fontSize: 18),
                            )),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.title,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isActive ? indigoFaint : textPrimary,
                                fontWeight: FontWeight.w600, fontSize: 14,
                              )),
                            const SizedBox(height: 2),
                            Text(
                              '${s.messages.where((m) => m.isUser).length} messages · ${_formatDate(s.createdAt)}',
                              style: const TextStyle(color: textMuted, fontSize: 11),
                            ),
                          ])),
                          if (isActive)
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: indigo, shape: BoxShape.circle),
                            ),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][dt.month - 1]}';
  }

  void _showKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        title: const Text('API Key', style: TextStyle(color: textPrimary)),
        content: const Text('Remove your stored API key?', style: TextStyle(color: textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: textMuted))),
          TextButton(onPressed: () { Navigator.pop(context); _clearKey(); }, child: const Text('Remove', style: TextStyle(color: red))),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final List<String> suggestions;
  final bool loading;
  final ValueChanged<String> onTap;
  const _EmptyState({required this.suggestions, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: indigo.withValues(alpha: 0.3)),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('👋 Hey, I\'m your AI Coach!', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text(
              'I know your fitness level, goal, streak, diet plan, and workout history. Ask me anything — I\'ll give you advice tailored to you.',
              style: TextStyle(color: textSecondary, fontSize: 13, height: 1.6),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          const Text('TRY ASKING', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          if (loading) ...[
            const SizedBox(width: 10),
            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: indigo)),
          ],
        ]),
        const SizedBox(height: 12),
        ...suggestions.map((s) => GestureDetector(
          onTap: () => onTap(s),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: surface2)),
            child: Row(children: [
              Expanded(child: Text(s, style: const TextStyle(color: textPrimary, fontSize: 14))),
              const Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 12),
            ]),
          ),
        )),
      ],
    );
  }
}

// ─── Chat bubble ──────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final ChatMsg msg;
  final ValueChanged<String>? onFollowup;
  const _Bubble({required this.msg, this.onFollowup});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser)
                Container(
                  width: 28, height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [indigo, Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser ? const LinearGradient(colors: [indigo, Color(0xFF6D28D9)]) : null,
                    color: isUser ? null : surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(msg.text, style: TextStyle(color: msg.isError ? red : Colors.white, fontSize: 14, height: 1.55)),
                ),
              ),
              if (isUser) const SizedBox(width: 4),
            ],
          ),
          if (!isUser && msg.followups.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Wrap(
                spacing: 6, runSpacing: 6,
                children: msg.followups.map((q) => GestureDetector(
                  onTap: () => onFollowup?.call(q),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: indigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: indigo.withValues(alpha: 0.35)),
                    ),
                    child: Text(q, style: const TextStyle(color: indigoFaint, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          width: 28, height: 28,
          margin: const EdgeInsets.only(right: 8, bottom: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [indigo, Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Text('🤖', style: TextStyle(fontSize: 14))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16), topRight: Radius.circular(16),
              bottomRight: Radius.circular(16), bottomLeft: Radius.circular(4),
            ),
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = ((_ctrl.value + i / 3.0) % 1.0);
                final opacity = phase < 0.5 ? phase * 2 : (1.0 - phase) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 7, height: 7,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: indigo.withValues(alpha: 0.3 + 0.7 * opacity)),
                );
              }),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── API key setup ─────────────────────────────────────────────────────────────

class _KeySetup extends StatelessWidget {
  final TextEditingController ctrl;
  final ValueChanged<String> onSave;
  final bool showKey;
  final VoidCallback onToggleShow;
  const _KeySetup({required this.ctrl, required this.onSave, required this.showKey, required this.onToggleShow});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
      children: [
        const Text('AI COACH', style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 36),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: indigo.withValues(alpha: 0.3)),
          ),
          child: const Column(children: [
            Text('🤖', style: TextStyle(fontSize: 56)),
            SizedBox(height: 16),
            Text('One-Time Setup', style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text(
              'Enter your OpenAI or Groq API key. Stored only on your device.',
              style: TextStyle(color: textSecondary, fontSize: 13, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
        const SizedBox(height: 32),
        const Text('API KEY', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: !showKey,
          style: const TextStyle(color: textPrimary, fontSize: 13, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'sk-... or gsk-...',
            hintStyle: const TextStyle(color: textMuted),
            filled: true, fillColor: surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: surface2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: surface2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: indigo)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixIcon: const Icon(Icons.key_rounded, color: textMuted, size: 18),
            suffixIcon: GestureDetector(
              onTap: onToggleShow,
              child: Icon(showKey ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: textMuted, size: 18),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('OpenAI: platform.openai.com  ·  Groq: console.groq.com', style: TextStyle(color: textMuted, fontSize: 12)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => onSave(ctrl.text),
          style: ElevatedButton.styleFrom(
            backgroundColor: indigo, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Activate AI Coach', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ],
    );
  }
}
