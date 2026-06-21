import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _toggleNotifications(BuildContext context, AppProvider p) async {
    final willEnable = !p.notificationsEnabled;
    p.toggleNotifications();
    if (willEnable) {
      final granted = await NotificationService.requestPermission();
      if (granted) {
        await NotificationService.scheduleDaily(p.reminderHour, p.reminderMinute);
      } else {
        p.toggleNotifications(); // revert — permission denied
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Allow notifications in system settings to enable reminders',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            backgroundColor: red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            duration: const Duration(seconds: 3),
          ));
        }
      }
    } else {
      await NotificationService.cancel();
    }
  }

  Future<void> _pickReminderTime(BuildContext context, AppProvider p) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: p.reminderHour, minute: p.reminderMinute),
    );
    if (picked != null) {
      p.setReminderTime(picked.hour, picked.minute);
      if (p.notificationsEnabled) {
        await NotificationService.scheduleDaily(picked.hour, picked.minute);
      }
    }
  }

  void _editName(BuildContext context, AppProvider p) {
    String draft = p.userName == 'Athlete' ? '' : p.userName;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        title: const Text('Your Name', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
        content: TextFormField(
          initialValue: draft,
          autofocus: true,
          onChanged: (v) => draft = v,
          style: const TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: textMuted),
            filled: true, fillColor: bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: surface2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: surface2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: indigo)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: textMuted))),
          TextButton(
            onPressed: () { p.setUserName(draft); Navigator.pop(context); },
            child: const Text('Save', style: TextStyle(color: indigo, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final levelNames = ['Noob','Beginner','Intermediate','Advanced','Expert'];

    return ListView(padding: const EdgeInsets.only(bottom: 100), children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)]),
        ),
        child: Row(children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [indigo, Color(0xFF8B5CF6)]),
            ),
            child: const Center(child: Text('🏋️', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => _editName(context, p),
                child: Row(children: [
                  Flexible(child: Text(p.userName,
                    style: const TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, color: textMuted, size: 15),
                ]),
              ),
              Text('${levelNames[(p.userLevel - 1).clamp(0, 4)]} · ${p.totalWorkouts} workouts completed',
                style: const TextStyle(color: indigoLight, fontSize: 14)),
            ]),
          ),
        ]),
      ),

      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(children: [
          // Level selector
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🎯 Your Fitness Level', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              ...levelNames.asMap().entries.map((e) {
                final isSelected = p.userLevel == e.key + 1;
                return GestureDetector(
                  onTap: () => p.setUserLevel(e.key + 1),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? indigo.withValues(alpha: 0.15) : bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? indigo : surface2),
                    ),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: levelColor(e.key + 1))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.value, style: TextStyle(color: isSelected ? indigoFaint : textSecondary, fontWeight: FontWeight.w600, fontSize: 14))),
                      if (isSelected) const Icon(Icons.check, color: indigo, size: 18),
                    ]),
                  ),
                );
              }),
            ]),
          ),

          // Body metrics (#4)
          _BodyMetricsCard(p: p),

          // Goal selector
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🏆 Your Goal', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: ['Build Muscle','Lose Fat','Get Stronger','Improve Endurance','Stay Active'].map((g) {
                final active = p.selectedGoal == g;
                return GestureDetector(
                  onTap: () => p.setSelectedGoal(g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? indigo.withValues(alpha: 0.2) : bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? indigo : surface2),
                    ),
                    child: Text(g, style: TextStyle(color: active ? indigoFaint : textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList()),
            ]),
          ),

          // Settings
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⚙️ Settings', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Workout Reminders', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Daily reminder to train', style: TextStyle(color: textMuted, fontSize: 12)),
                ]),
                GestureDetector(
                  onTap: () => _toggleNotifications(context, p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48, height: 26,
                    decoration: BoxDecoration(
                      color: p.notificationsEnabled ? indigo : surface2,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: p.notificationsEnabled ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20, height: 20, margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ]),
              if (p.notificationsEnabled) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _pickReminderTime(context, p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: surface2)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Row(children: [
                        Icon(Icons.schedule, color: textMuted, size: 16),
                        SizedBox(width: 8),
                        Text('Reminder time', style: TextStyle(color: textSecondary, fontSize: 13)),
                      ]),
                      Text(
                        TimeOfDay(hour: p.reminderHour, minute: p.reminderMinute).format(context),
                        style: const TextStyle(color: indigoFaint, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ]),
                  ),
                ),
              ],
              const Divider(color: surface2, height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Vibration & Sound', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Haptic feedback during workouts', style: TextStyle(color: textMuted, fontSize: 12)),
                ]),
                GestureDetector(
                  onTap: () => p.toggleVibration(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48, height: 26,
                    decoration: BoxDecoration(
                      color: p.vibrationEnabled ? indigo : surface2,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: p.vibrationEnabled ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20, height: 20, margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ]),
              const Divider(color: surface2, height: 24),
              const Text('FitForge v2.0 · Built for India 🇮🇳', style: TextStyle(color: textMuted, fontSize: 13)),
            ]),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Body metrics (#4) ──────────────────────────────────────────────────────────

class _BodyMetricsCard extends StatelessWidget {
  final AppProvider p;
  const _BodyMetricsCard({required this.p});

  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BodyMetricsSheet(p: p),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('📏 Body Metrics', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          GestureDetector(
            onTap: () => _edit(context),
            child: Row(children: [
              Text(p.hasBodyMetrics ? 'Edit' : 'Add', style: const TextStyle(color: indigoFaint, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              const Icon(Icons.edit_outlined, color: indigoFaint, size: 14),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        if (!p.hasBodyMetrics)
          GestureDetector(
            onTap: () => _edit(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: surface2)),
              child: const Column(children: [
                Text('Add your weight, height & age', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('Get a calorie target personalized to your body', style: TextStyle(color: textMuted, fontSize: 12), textAlign: TextAlign.center),
              ]),
            ),
          )
        else ...[
          Row(children: [
            _MetricChip(p.weightKg!.toStringAsFixed(p.weightKg! % 1 == 0 ? 0 : 1), 'kg'),
            const SizedBox(width: 8),
            _MetricChip('${p.heightCm}', 'cm'),
            const SizedBox(width: 8),
            _MetricChip('${p.age}', 'yrs'),
            const SizedBox(width: 8),
            _MetricChip(p.sex == 'female' ? '♀' : '♂', p.sex == 'female' ? 'Female' : 'Male'),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF134E4A), Color(0xFF0F172A)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: teal.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _MetricStat('${p.bmr!.round()}', 'BMR'),
                _MetricStat('${p.tdee!.round()}', 'TDEE · ${p.activity}'),
                _MetricStat('${p.recommendedCalories}', 'Suggested'),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: p.recommendedCalories == p.calorieGoal
                      ? null
                      : () {
                          p.applyRecommendedCalories();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Calorie goal set to ${p.recommendedCalories} kcal',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            backgroundColor: const Color(0xFF1E1B4B),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            duration: const Duration(seconds: 2),
                          ));
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: surface2,
                    disabledForegroundColor: textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    p.recommendedCalories == p.calorieGoal
                        ? 'Goal matches recommendation ✓'
                        : 'Use ${p.recommendedCalories} kcal as my goal',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Text('Estimate for "${p.selectedGoal}" using Mifflin-St Jeor. Adjust as needed.',
            style: const TextStyle(color: textMuted, fontSize: 11)),
        ],
      ]),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String value, label;
  const _MetricChip(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(color: textMuted, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _MetricStat extends StatelessWidget {
  final String value, label;
  const _MetricStat(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
      Text(label, style: const TextStyle(color: textSecondary, fontSize: 10)),
    ]);
  }
}

class _BodyMetricsSheet extends StatefulWidget {
  final AppProvider p;
  const _BodyMetricsSheet({required this.p});

  @override
  State<_BodyMetricsSheet> createState() => _BodyMetricsSheetState();
}

class _BodyMetricsSheetState extends State<_BodyMetricsSheet> {
  late final TextEditingController _weight;
  late final TextEditingController _height;
  late final TextEditingController _age;
  late String _sex;
  late String _activity;

  @override
  void initState() {
    super.initState();
    final p = widget.p;
    _weight = TextEditingController(text: p.weightKg != null ? p.weightKg!.toStringAsFixed(p.weightKg! % 1 == 0 ? 0 : 1) : '');
    _height = TextEditingController(text: p.heightCm?.toString() ?? '');
    _age = TextEditingController(text: p.age?.toString() ?? '');
    _sex = p.sex;
    _activity = p.activity;
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    _age.dispose();
    super.dispose();
  }

  void _save() {
    final w = double.tryParse(_weight.text.trim());
    final h = int.tryParse(_height.text.trim());
    final a = int.tryParse(_age.text.trim());
    if (w == null || h == null || a == null || w < 20 || w > 400 || h < 80 || h > 260 || a < 10 || a > 120) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Enter a valid weight (20–400kg), height (80–260cm) and age (10–120)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        duration: const Duration(seconds: 3),
      ));
      return;
    }
    widget.p.updateBodyMetrics(weightKg: w, heightCm: h, age: a, sex: _sex, activity: _activity);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft,
            child: Text('BODY METRICS', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _field(_weight, 'Weight', 'kg')),
            const SizedBox(width: 10),
            Expanded(child: _field(_height, 'Height', 'cm')),
            const SizedBox(width: 10),
            Expanded(child: _field(_age, 'Age', 'yrs')),
          ]),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft,
            child: Text('SEX (for BMR formula)', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1))),
          const SizedBox(height: 8),
          Row(children: [
            _toggle('Male', _sex == 'male', () => setState(() => _sex = 'male')),
            const SizedBox(width: 10),
            _toggle('Female', _sex == 'female', () => setState(() => _sex = 'female')),
          ]),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft,
            child: Text('ACTIVITY LEVEL', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: activityFactors.keys.map((a) {
            final active = a == _activity;
            return GestureDetector(
              onTap: () => setState(() => _activity = a),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: active ? indigo.withValues(alpha: 0.2) : bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? indigo : surface2),
                ),
                child: Text(a, style: TextStyle(color: active ? indigoFaint : textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            );
          }).toList()),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Save Metrics', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, String unit) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          suffixText: unit,
          suffixStyle: const TextStyle(color: textMuted, fontSize: 12),
          filled: true, fillColor: bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: surface2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: surface2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: indigo)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _toggle(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? indigo.withValues(alpha: 0.2) : bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? indigo : surface2),
          ),
          child: Center(child: Text(label, style: TextStyle(color: active ? indigoFaint : textMuted, fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }
}
