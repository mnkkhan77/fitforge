import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final levelNames = ['Noob','Beginner','Intermediate','Advanced','Expert'];
    final last7 = p.history.length >= 7 ? p.history.sublist(p.history.length - 7) : p.history;
    int _cal(Map d) => ((d['calories'] as int?) ?? 0);
    final maxCal = last7.fold(1, (a, d) => _cal(d) > a ? _cal(d) : a);
    // Weeks newest-first: i=0 = this week, i=1 = last week, etc.
    final histLen = p.history.length;
    final weeks = List.generate(4, (i) {
      final end = histLen - i * 7;
      if (end <= 0) return 0;
      final start = (end - 7).clamp(0, histLen);
      return p.history.sublist(start, end).fold(0, (a, d) => a + _cal(d));
    });
    const weekLabels = ['This Week', 'Last Week', '2 Wks Ago', '3 Wks Ago'];
    final maxWeek = weeks.fold(1, (a, v) => v > a ? v : a);

    final daysTracked = p.history.length;
    final consistencyPct = daysTracked > 0 ? ((p.totalWorkouts / daysTracked) * 100).round() : 0;

    return ListView(padding: const EdgeInsets.fromLTRB(20, 48, 20, 100), children: [
      const Text('PROGRESS', style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
      const SizedBox(height: 20),

      if (p.history.isEmpty) ...[
        const SizedBox(height: 60),
        Center(child: Column(children: [
          const Text('📊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          const Text('No data yet', style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text('Complete your first workout session\nto start seeing progress here.',
            style: TextStyle(color: textMuted, fontSize: 14, height: 1.6), textAlign: TextAlign.center),
        ])),
      ] else ...[

      // Level card
      Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF312E81)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: indigo.withOpacity(0.3)),
        ),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CURRENT LEVEL', style: TextStyle(color: textSecondary, fontSize: 12)),
              Text(levelNames[(p.userLevel - 1).clamp(0, 4)],
                style: const TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
            ]),
            const Icon(Icons.star, color: indigoLight, size: 28),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (p.userLevel - 1) / 4,
              backgroundColor: Colors.black26,
              valueColor: const AlwaysStoppedAnimation(indigo),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Noob', style: TextStyle(color: textMuted, fontSize: 11)),
            Text('Expert', style: TextStyle(color: textMuted, fontSize: 11)),
          ]),
        ]),
      ),

      // Stats grid
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _StatTile('🔥', '${p.streak}', 'Day Streak'),
          _StatTile('💪', '${p.totalWorkouts}', 'Total Sessions'),
          _StatTile('⚡', '${p.weeklyCalsBurned}', 'Week kcal'),
          _StatTile('📊', '$consistencyPct%', 'Consistency'),
        ],
      ),
      const SizedBox(height: 20),

      // Bar chart
      Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Last 7 Days — Calories Burned', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: last7.asMap().entries.map((entry) {
              final d = entry.value;
              final cal = ((d['calories'] as int?) ?? 0);
              final h = cal > 0 ? (cal / maxCal) * 78 : 0.0;
              const days = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
              String dayStr;
              try { dayStr = days[DateTime.parse(d['date'].toString()).weekday % 7]; }
              catch (_) { dayStr = '?'; }
              return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                if (cal > 0) Text('$cal', style: const TextStyle(color: textMuted, fontSize: 9)),
                const SizedBox(height: 2),
                Container(
                  height: h.toDouble(),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    gradient: d['worked'] == true
                      ? const LinearGradient(colors: [indigo, Color(0xFF8B5CF6)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
                      : null,
                    color: d['worked'] == true ? null : surface2,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(dayStr, style: const TextStyle(color: textMuted, fontSize: 9)),
              ]));
            }).toList()),
          ),
        ]),
      ),

      // Weekly totals
      Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Weekly Calorie Totals', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...weeks.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(weekLabels[e.key], style: const TextStyle(color: textSecondary, fontSize: 13)),
                Text('${e.value} kcal', style: const TextStyle(color: indigoLight, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (e.value / maxWeek).clamp(0.0, 1.0),
                  backgroundColor: bg,
                  valueColor: const AlwaysStoppedAnimation(indigo),
                  minHeight: 8,
                ),
              ),
            ]),
          )),
        ]),
      ),

      // Heatmap
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Activity Heatmap · ${p.history.length} days', style: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Wrap(spacing: 3, runSpacing: 3, children: p.history.map((d) {
            final cal = ((d['calories'] as int?) ?? 0);
            Color color;
            if (d['worked'] == true) {
              if (cal > 300) color = indigo;
              else if (cal > 200) color = indigoLight;
              else color = indigoFaint;
            } else {
              color = surface;
            }
            return Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2),
                border: Border.all(color: bg, width: 0.5)));
          }).toList()),
          const SizedBox(height: 12),
          const Row(children: [
            Text('Less', style: TextStyle(color: textMuted, fontSize: 11)),
            SizedBox(width: 6),
            _HeatDot(surface),
            SizedBox(width: 3),
            _HeatDot(indigoFaint),
            SizedBox(width: 3),
            _HeatDot(indigoLight),
            SizedBox(width: 3),
            _HeatDot(indigo),
            SizedBox(width: 6),
            Text('More', style: TextStyle(color: textMuted, fontSize: 11)),
          ]),
        ]),
      ),

      ], // end else
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final String icon, value, label;
  const _StatTile(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: surface2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(icon, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: textMuted, fontSize: 11)),
      ]),
    );
  }
}

class _HeatDot extends StatelessWidget {
  final Color color;
  const _HeatDot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));
  }
}
