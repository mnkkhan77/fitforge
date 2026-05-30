import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../data/workout_plans_data.dart';
import '../data/exercises_data.dart';
import '../models/workout_day.dart';
import '../theme.dart';
import '../widgets/level_badge.dart';
import 'session_screen.dart';
import 'exercise_detail_screen.dart';

class WeeklyScreen extends StatelessWidget {
  const WeeklyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final planType = p.selectedPlanType;

    if (planType == null) return _PlanSelector();
    final plan = planType == '5day' ? plan5Day : plan7Day;
    return _WeekView(plan: plan);
  }
}

class _PlanSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          color: bg,
          width: double.infinity,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('WEEKLY PLAN', style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 6),
            const Text('Choose your training structure', style: TextStyle(color: textMuted, fontSize: 14)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(children: [
            _PlanOptionCard(
              emoji: '😌', title: '5-Day Plan', tag: 'Recommended',
              sub: 'Train 5 days, 2 complete rest days',
              desc: 'Best for beginners and intermediates. Your body gets full recovery time between sessions.',
              onTap: () => context.read<AppProvider>().setSelectedPlanType('5day'),
            ),
            const SizedBox(height: 16),
            _PlanOptionCard(
              emoji: '🔥', title: '7-Day Plan', tag: 'Advanced',
              sub: 'Train all 7 days (2 lighter days)',
              desc: 'For advanced athletes who need daily structure. Two lighter days replace full rest.',
              onTap: () => context.read<AppProvider>().setSelectedPlanType('7day'),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PlanOptionCard extends StatelessWidget {
  final String emoji, title, tag, sub, desc;
  final VoidCallback onTap;
  const _PlanOptionCard({required this.emoji, required this.title, required this.tag, required this.sub, required this.desc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: surface2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: indigo.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(tag, style: const TextStyle(color: indigoFaint, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: indigoLight, fontSize: 13)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: textMuted, fontSize: 13, height: 1.5)),
        ]),
      ),
    );
  }
}

class _WeekView extends StatelessWidget {
  final WorkoutPlan plan;
  const _WeekView({required this.plan});

  @override
  Widget build(BuildContext context) {
    final todayName = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][DateTime.now().weekday % 7];
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
        color: bg,
        width: double.infinity,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextButton.icon(
            onPressed: () => context.read<AppProvider>().setSelectedPlanType(null),
            icon: const Icon(Icons.arrow_back, size: 16, color: textSecondary),
            label: const Text('Change Plan Type', style: TextStyle(color: textSecondary)),
          ),
          const Text('YOUR WEEK', style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
          Text(plan.label, style: const TextStyle(color: indigoLight, fontSize: 13)),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: plan.days.length,
          itemBuilder: (ctx, i) {
            final day = plan.days[i] as WorkoutDay;
            final isToday = day.day == todayName;
            final dayExs = day.exerciseIds.map((id) => exercises.firstWhere((e) => e.id == id, orElse: () => exercises[0])).toList();
            return GestureDetector(
              onTap: () => Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => _DayDetailScreen(day: day, isToday: isToday))),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: isToday ? const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]) : null,
                  color: isToday ? null : surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isToday ? indigo.withOpacity(0.5) : surface2),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(day.day.toUpperCase(),
                        style: TextStyle(color: isToday ? indigoFaint : textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: indigo, borderRadius: BorderRadius.circular(10)),
                          child: const Text('TODAY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                      ],
                      if (day.isRest) ...[
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: green.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          child: const Text('REST', style: TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.w700))),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    Text(day.label, style: const TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(day.focus, style: const TextStyle(color: textMuted, fontSize: 12)),
                    if (!day.isRest && dayExs.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(spacing: 4, runSpacing: 4, children: [
                        ...dayExs.take(3).map((ex) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                          child: Text('${ex.emoji} ${ex.name}', style: const TextStyle(color: textSecondary, fontSize: 11)),
                        )),
                        if (dayExs.length > 3) Text('+${dayExs.length - 3} more', style: const TextStyle(color: textMuted, fontSize: 11)),
                      ]),
                    ],
                  ])),
                  const Icon(Icons.chevron_right, color: surface2, size: 20),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _DayDetailScreen extends StatelessWidget {
  final WorkoutDay day;
  final bool isToday;
  const _DayDetailScreen({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final dayExs = day.exerciseIds.map((id) => exercises.firstWhere((e) => e.id == id, orElse: () => exercises[0])).toList();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            color: bg,
            width: double.infinity,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.arrow_back, size: 16, color: textSecondary),
                    SizedBox(width: 6),
                    Text('Back to Week', style: TextStyle(color: textSecondary, fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: indigo.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(day.day, style: const TextStyle(color: indigoFaint, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Text(day.label, style: const TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text(day.focus, style: const TextStyle(color: textMuted, fontSize: 14)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: day.isRest
              ? _RestDayContent()
              : Column(children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: indigo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: indigo.withOpacity(0.2)),
                    ),
                    child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('📋 Perform in this exact order', style: TextStyle(color: indigoLight, fontSize: 13, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Cardio first warms your heart and lungs, then compound movements when you\'re peak-energy, isolation or core last.',
                        style: TextStyle(color: textMuted, fontSize: 13, height: 1.5)),
                    ]),
                  ),
                  ...dayExs.asMap().entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: surface2)),
                    child: Row(children: [
                      Container(width: 32, height: 32,
                        decoration: BoxDecoration(color: indigo.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: indigoLight, fontWeight: FontWeight.w800, fontSize: 14)))),
                      const SizedBox(width: 10),
                      Container(width: 44, height: 44,
                        decoration: BoxDecoration(color: levelBg(e.value.level), borderRadius: BorderRadius.circular(12)),
                        child: Center(child: Text(e.value.emoji, style: const TextStyle(fontSize: 22)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.value.name, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('${e.value.sets} sets × ${e.value.reps != null ? "${e.value.reps} reps" : "${e.value.duration}s"} · Rest ${e.value.restSeconds}s',
                          style: const TextStyle(color: textMuted, fontSize: 12)),
                      ])),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailScreen(exercise: e.value))),
                        child: const Text('How?', style: TextStyle(color: indigoFaint, fontSize: 11)),
                      ),
                    ]),
                  )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => SessionScreen(dayExercises: dayExs))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("START TODAY'S SESSION 💪",
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1)),
                    ),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _RestDayContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.only(top: 40),
        child: Column(children: [
          Text('😴', style: TextStyle(fontSize: 80)),
          SizedBox(height: 20),
          Text('Rest Day', style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text(
            'Rest days are where the real gains happen. Your muscles repair and grow during recovery — not during the workout itself. Light stretching or a walk is fine.',
            style: TextStyle(color: textMuted, fontSize: 14, height: 1.7),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}
