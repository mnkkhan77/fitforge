import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';
import '../models/exercise.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class SessionScreen extends StatefulWidget {
  final List<Exercise> dayExercises;
  const SessionScreen({super.key, required this.dayExercises});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  int _currentIdx = 0;
  int _currentSet = 1;
  String _phase = 'exercise'; // 'exercise' | 'rest' | 'done'
  int? _timeLeft;
  bool _running = false;
  final List<int> _completedIds = [];
  Timer? _timer;

  Exercise get current => widget.dayExercises[_currentIdx.clamp(0, widget.dayExercises.length - 1)];
  // Level-adjusted targets (#5): the same plan scales to the user's level.
  int get _level => context.read<AppProvider>().userLevel;
  int get _sets => adjustedSets(current.sets, _level);
  int get _rest => adjustedRest(current.restSeconds, _level);
  int get totalCalories => _completedIds.fold(0, (a, id) {
    try { return a + widget.dayExercises.firstWhere((e) => e.id == id).calories; }
    catch (_) { return a; }
  });

  @override
  void initState() {
    super.initState();
    _setTimerForPhase();
  }

  void _setTimerForPhase() {
    if (widget.dayExercises.isEmpty) return;
    if (_phase == 'exercise' && current.reps == null) {
      setState(() => _timeLeft = current.duration);
    } else if (_phase == 'rest') {
      setState(() => _timeLeft = _rest);
      _startTimer();
    } else {
      setState(() => _timeLeft = null);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft != null && _timeLeft! > 0) {
        setState(() => _timeLeft = _timeLeft! - 1);
        if (_timeLeft == 3) _vibrate([200]);
      } else {
        _timer?.cancel();
        setState(() => _running = false);
        _vibrate([300, 100, 300]);
      }
    });
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      _startTimer();
    }
  }

  Future<void> _vibrate(List<int> pattern) async {
    if (!mounted) return;
    if (!context.read<AppProvider>().vibrationEnabled) return;
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) Vibration.vibrate(pattern: pattern);
    } catch (_) {}
  }

  void _handleComplete() {
    _timer?.cancel();
    if (_currentSet < _sets) {
      setState(() {
        _currentSet++;
        _phase = 'rest';
        _timeLeft = _rest;
        _running = false;
      });
      _startTimer();
    } else {
      setState(() => _completedIds.add(current.id));
      if (_currentIdx < widget.dayExercises.length - 1) {
        setState(() {
          _currentIdx++;
          _currentSet = 1;
          _phase = 'exercise';
          _timeLeft = null;
          _running = false;
        });
        _setTimerForPhase();
      } else {
        final cal = totalCalories;
        setState(() => _phase = 'done');
        _vibrate([400, 200, 400, 200, 800]);
        if (mounted) context.read<AppProvider>().logWorkout(calories: cal);
      }
    }
  }

  void _handleSkip() {
    _timer?.cancel();
    setState(() => _completedIds.add(current.id));
    if (_currentIdx < widget.dayExercises.length - 1) {
      setState(() {
        _currentIdx++;
        _currentSet = 1;
        _phase = 'exercise';
        _timeLeft = null;
        _running = false;
      });
      _setTimerForPhase();
    } else {
      final cal = totalCalories;
      setState(() => _phase = 'done');
      if (mounted) context.read<AppProvider>().logWorkout(calories: cal);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 'done') return _DoneScreen(completed: _completedIds.length, calories: totalCalories);
    if (widget.dayExercises.isEmpty) return const Scaffold(body: Center(child: Text('No exercises found.', style: TextStyle(color: textMuted))));

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          // Top bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
            color: bg,
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                GestureDetector(
                  onTap: () => _showExitDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
                    child: const Text('✕ Exit', style: TextStyle(color: textSecondary, fontSize: 13)),
                  ),
                ),
                Text('${_currentIdx + 1} / ${widget.dayExercises.length}',
                  style: const TextStyle(color: textMuted, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _currentIdx / widget.dayExercises.length,
                  backgroundColor: surface,
                  valueColor: const AlwaysStoppedAnimation(indigo),
                  minHeight: 6,
                ),
              ),
            ]),
          ),

          // Rest banner
          if (_phase == 'rest')
            Container(
              color: amber.withValues(alpha: 0.15),
              padding: const EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              child: const Center(
                child: Text('😮‍💨 REST TIME — Get ready for the next set',
                  style: TextStyle(color: amber, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Exercise card
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)]),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: indigo.withValues(alpha: 0.2)),
                ),
                child: Column(children: [
                  Text(current.emoji, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 12),
                  Text(current.name,
                    style: const TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                    textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Set $_currentSet of $_sets', style: const TextStyle(color: indigoLight, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_sets, (i) =>
                    Container(
                      width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _currentSet - 1 ? indigo : i == _currentSet - 1 ? indigoFaint : surface,
                        border: Border.all(color: surface2),
                      ),
                    ),
                  )),
                ]),
              ),
              const SizedBox(height: 14),

              // Target
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: surface2)),
                child: Column(children: [
                  const Text('TARGET', style: TextStyle(color: textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    current.reps != null ? '${current.reps} REPS' : '${current.duration}s',
                    style: const TextStyle(color: textPrimary, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                ]),
              ),
              const SizedBox(height: 14),

              // Timer
              if (_timeLeft != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: surface2)),
                  child: Column(children: [
                    Text(_phase == 'rest' ? 'REST TIMER' : 'TIMER',
                      style: const TextStyle(color: textMuted, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(
                      '${(_timeLeft! ~/ 60).toString().padLeft(2, '0')}:${(_timeLeft! % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _timeLeft! < 10 ? red : textPrimary,
                        fontSize: 54, fontWeight: FontWeight.w900, letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _toggleTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: indigo.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: indigo.withValues(alpha: 0.4)),
                        ),
                        child: Text(_running ? '⏸ Pause' : '▶ Resume',
                          style: const TextStyle(color: indigoFaint, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ),
              const SizedBox(height: 14),

              // Action buttons
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _handleSkip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: surface2)),
                      child: const Center(child: Text('⏭ Skip', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: GestureDetector(
                    onTap: _handleComplete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [indigo, Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: Text('✓ DONE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // Up next
              if (_currentIdx + 1 < widget.dayExercises.length) ...[
                const Align(alignment: Alignment.centerLeft,
                  child: Text('UP NEXT', style: TextStyle(color: textMuted, fontSize: 12))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: surface2)),
                  child: Row(children: [
                    Text(widget.dayExercises[_currentIdx + 1].emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.dayExercises[_currentIdx + 1].name,
                        style: const TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${adjustedSets(widget.dayExercises[_currentIdx + 1].sets, _level)} sets × ${widget.dayExercises[_currentIdx + 1].reps != null ? "${widget.dayExercises[_currentIdx + 1].reps} reps" : "${widget.dayExercises[_currentIdx + 1].duration}s"}',
                        style: const TextStyle(color: textMuted, fontSize: 12)),
                    ]),
                  ]),
                ),
              ],
              const SizedBox(height: 80),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: surface,
      title: const Text('Exit Workout?', style: TextStyle(color: textPrimary)),
      content: const Text('Your progress will be lost.', style: TextStyle(color: textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Going', style: TextStyle(color: indigo))),
        TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
          child: const Text('Exit', style: TextStyle(color: red))),
      ],
    ));
  }
}

class _DoneScreen extends StatelessWidget {
  final int completed, calories;
  const _DoneScreen({required this.completed, required this.calories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text('WORKOUT COMPLETE!',
              style: TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('Gains are loading... 💪', style: TextStyle(color: indigoLight, fontSize: 16)),
            const SizedBox(height: 30),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _DoneStat('$completed', 'Exercises'),
              const SizedBox(width: 16),
              _DoneStat('~$calories', 'kcal Burned'),
            ]),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DoneStat extends StatelessWidget {
  final String value, label;
  const _DoneStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(value, style: const TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: textMuted, fontSize: 12)),
      ]),
    );
  }
}
