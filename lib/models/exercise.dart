class Exercise {
  final int id;
  final String name;
  final String category;
  final String muscle;
  final int level;
  final String levelName;
  final int sets;
  final int? reps;
  final int duration;
  final int restSeconds;
  final String frequency;
  final int calories;
  final List<String> howTo;
  final List<String> warnings;
  final List<String> muscles;
  final String emoji;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.muscle,
    required this.level,
    required this.levelName,
    required this.sets,
    this.reps,
    required this.duration,
    required this.restSeconds,
    required this.frequency,
    required this.calories,
    required this.howTo,
    required this.warnings,
    required this.muscles,
    required this.emoji,
  });
}
