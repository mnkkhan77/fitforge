class WorkoutDay {
  final String day;
  final String label;
  final String focus;
  final List<int> exerciseIds;
  final bool isRest;

  const WorkoutDay({
    required this.day,
    required this.label,
    required this.focus,
    required this.exerciseIds,
    required this.isRest,
  });
}

class WorkoutPlan {
  final String key;
  final String label;
  final List<WorkoutDay> days;

  const WorkoutPlan({
    required this.key,
    required this.label,
    required this.days,
  });
}
