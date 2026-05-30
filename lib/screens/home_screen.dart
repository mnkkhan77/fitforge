import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import '../data/workout_plans_data.dart';
import '../data/exercises_data.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onTabChange;
  const HomeScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'GOOD MORNING' : hour < 17 ? 'GOOD AFTERNOON' : 'GOOD EVENING';
    final todayName = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'][DateTime.now().weekday % 7];
    final activePlan = p.selectedPlanType == null ? null
        : p.selectedPlanType == '7day' ? plan7Day : plan5Day;
    final todayPlan = activePlan?.days.firstWhere((d) => d.day == todayName, orElse: () => activePlan.days[0]);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final todayCalOut = p.history
        .where((d) => d['date'] == todayStr)
        .fold(0, (a, d) => a + ((d['calories'] as int?) ?? 0));
    final net = p.todayCalIn - todayCalOut;

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0F172A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greeting, style: const TextStyle(color: textMuted, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('${p.userName.toUpperCase()} 🔥',
              style: TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 20),
            Row(children: [
              _StatCard(icon: '🔥', label: 'Streak', value: '${p.streak}'),
              const SizedBox(width: 10),
              _StatCard(icon: '💪', label: 'Workouts', value: '${p.totalWorkouts}'),
              const SizedBox(width: 10),
              _StatCard(icon: '⚡', label: 'kcal/wk', value: '${p.weeklyCalsBurned}'),
            ]),
          ]),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(children: [
            // Calorie card
            GestureDetector(
              onTap: () => onTabChange(3),
              child: Container(
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF134E4A), Color(0xFF0F172A)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: teal.withOpacity(0.3)),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('🥗 Today\'s Calories', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                    const Text('Log food →', style: TextStyle(color: teal, fontSize: 12)),
                  ]),
                  const SizedBox(height: 14),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _CalStat('Eaten', p.todayCalIn, green),
                    _CalStat('Burned', todayCalOut, orange),
                    _CalStat('Net', net, net > p.calorieGoal ? red : indigoLight),
                  ]),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (p.todayCalIn / p.calorieGoal).clamp(0.0, 1.0),
                      backgroundColor: Colors.black26,
                      valueColor: const AlwaysStoppedAnimation(teal),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('${p.todayCalIn} / ${p.calorieGoal} kcal goal',
                      style: const TextStyle(color: textMuted, fontSize: 11)),
                  ),
                ]),
              ),
            ),

            // Today's workout
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Today — $todayName', style: const TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              TextButton(onPressed: () => onTabChange(2), child: const Text('Full plan →', style: TextStyle(color: indigoLight))),
            ]),
            const SizedBox(height: 8),
            if (activePlan == null)
              GestureDetector(
                onTap: () => onTabChange(2),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: surface2),
                  ),
                  child: const Column(children: [
                    Text('📋', style: TextStyle(fontSize: 36)),
                    SizedBox(height: 10),
                    Text('No training plan selected', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Tap to pick a 5-day or 7-day plan', style: TextStyle(color: textMuted, fontSize: 13)),
                  ]),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: indigo.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(todayPlan!.isRest ? '😴 Rest Day' : todayPlan.label,
                    style: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(todayPlan.focus, style: const TextStyle(color: indigoLight, fontSize: 13)),
                  if (!todayPlan.isRest) ...[
                    const SizedBox(height: 14),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      ...todayPlan.exerciseIds.take(4).map((id) {
                        final ex = exercises.firstWhere((e) => e.id == id, orElse: () => exercises[0]);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                          child: Text('${ex.emoji} ${ex.name}', style: const TextStyle(color: textSecondary, fontSize: 11)),
                        );
                      }),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => onTabChange(2),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('START WORKOUT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ]),
              ),
            const SizedBox(height: 100),
          ]),
        ),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon, label, value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          Text(value, style: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: textMuted, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _CalStat extends StatelessWidget {
  final String label;
  final int val;
  final Color color;
  const _CalStat(this.label, this.val, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$val', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: textMuted, fontSize: 11)),
    ]);
  }
}
