import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../theme.dart';
import '../widgets/level_badge.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _showHow = true;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [levelBg(ex.level), bg],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  LevelBadge(level: ex.level, label: ex.levelName),
                  const SizedBox(height: 10),
                  Text(ex.name, style: const TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text('${ex.category == "bodyweight" ? "🤸 Bodyweight" : "🏋️ Equipment"} · ${ex.muscle}',
                    style: const TextStyle(color: textSecondary, fontSize: 14)),
                ])),
                Text(ex.emoji, style: const TextStyle(fontSize: 56)),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _InfoChip(ex.sets > 0 ? '${ex.sets}' : '-', 'Sets'),
                _InfoChip(ex.reps != null ? '${ex.reps}' : '${ex.duration}s', ex.reps != null ? 'Reps' : 'Duration'),
                _InfoChip('${ex.restSeconds}s', 'Rest'),
                _InfoChip(ex.frequency, 'Freq'),
                _InfoChip('~${ex.calories}', 'kcal'),
              ]),
              const SizedBox(height: 16),
              Wrap(spacing: 6, runSpacing: 6, children: ex.muscles.map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: indigo.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(m, style: const TextStyle(color: indigoFaint, fontSize: 12)),
              )).toList()),
              const SizedBox(height: 20),
            ]),
          ),

          // Tabs
          Row(children: [
            _DetailTab('How To', _showHow, () => setState(() => _showHow = true)),
            _DetailTab('⚠️ Watch Out', !_showHow, () => setState(() => _showHow = false)),
          ]),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: _showHow
              ? Column(children: ex.howTo.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: indigo.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: indigo.withOpacity(0.4)),
                      ),
                      child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: indigoLight, fontWeight: FontWeight.w800, fontSize: 14))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(e.value, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.6)),
                    )),
                  ]),
                )).toList())
              : Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: red.withOpacity(0.3)),
                    ),
                    child: const Text('⚠️ Read carefully to avoid injury',
                      style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  ...ex.warnings.map((w) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: surface2)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('⚠️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(w, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.5))),
                    ]),
                  )),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String value, label;
  const _InfoChip(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w900, fontSize: 18)),
        Text(label, style: const TextStyle(color: textMuted, fontSize: 10)),
      ]),
    );
  }
}

class _DetailTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _DetailTab(this.label, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: surface,
            border: Border(bottom: BorderSide(color: active ? indigo : Colors.transparent, width: 2)),
          ),
          child: Center(child: Text(label,
            style: TextStyle(color: active ? indigo : textMuted, fontWeight: FontWeight.w600, fontSize: 13))),
        ),
      ),
    );
  }
}
