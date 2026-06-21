import 'package:flutter/material.dart';
import '../data/exercises_data.dart';
import '../models/exercise.dart';
import '../theme.dart';
import '../widgets/level_badge.dart';
import 'exercise_detail_screen.dart';

const _levels = ['All','Noob','Beginner','Intermediate','Advanced','Expert'];
const _muscles = ['All','Chest','Back','Legs','Shoulders','Arms','Core','Full Body'];

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _tab = 'bodyweight';
  String _level = 'All';
  String _muscle = 'All';
  String _search = '';

  List<Exercise> get filtered => exercises.where((e) =>
    e.category == _tab &&
    (_level == 'All' || e.levelName == _level) &&
    (_muscle == 'All' || e.muscle == _muscle) &&
    e.name.toLowerCase().contains(_search.toLowerCase())
  ).toList();

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    return Column(children: [
      Container(
        color: bg,
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('EXERCISE LIBRARY',
            style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: '🔍  Search exercises...',
              hintStyle: const TextStyle(color: textMuted),
              filled: true, fillColor: surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: surface2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: surface2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: indigo)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _TabBtn('🤸 Bodyweight', 'bodyweight', _tab, (v) => setState(() => _tab = v)),
            const SizedBox(width: 8),
            _TabBtn('🏋️ Equipment', 'equipment', _tab, (v) => setState(() => _tab = v)),
          ]),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _levels.map((l) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FilterChip(l, _level, (v) => setState(() => _level = v)),
            )).toList()),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _muscles.map((m) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _MuscleChip(m, _muscle, (v) => setState(() => _muscle = v)),
            )).toList()),
          ),
          const SizedBox(height: 12),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: list.isEmpty ? 1 : list.length + 1,
          itemBuilder: (ctx, i) {
            if (list.isEmpty) {
              return const Center(
                child: Padding(padding: EdgeInsets.only(top: 60),
                  child: Column(children: [
                    Text('🔍', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('No exercises found.', style: TextStyle(color: textMuted)),
                  ]),
                ),
              );
            }
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${list.length} exercises', style: const TextStyle(color: textMuted, fontSize: 13)),
              );
            }
            final ex = list[i - 1];
            return _ExerciseCard(ex: ex, onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ExerciseDetailScreen(exercise: ex))));
          },
        ),
      ),
    ]);
  }
}

class _ExerciseCard extends StatelessWidget {
  final Exercise ex;
  final VoidCallback onTap;
  const _ExerciseCard({required this.ex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: surface2),
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: levelBg(ex.level), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(ex.emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ex.name, style: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 3),
            Text('${ex.muscle} · ${ex.sets} sets · ${ex.frequency}',
              style: const TextStyle(color: textMuted, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            LevelBadge(level: ex.level, label: ex.levelName),
            const SizedBox(height: 4),
            Text('~${ex.calories} kcal', style: const TextStyle(color: textMuted, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label, value, current;
  final ValueChanged<String> onTap;
  const _TabBtn(this.label, this.value, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? indigo : surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(label,
            style: TextStyle(color: active ? Colors.white : textMuted, fontWeight: FontWeight.w700, fontSize: 13))),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label, current;
  final ValueChanged<String> onTap;
  const _FilterChip(this.label, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = label == current;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? indigo : surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String label, current;
  final ValueChanged<String> onTap;
  const _MuscleChip(this.label, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = label == current;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? indigo.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? indigo : surface2),
        ),
        child: Text(label, style: TextStyle(color: active ? indigoFaint : textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
