class DietPlan {
  final String id;
  final String name;
  final String goal;
  final String pref;
  final int targetCal;
  final int protein;
  final int carbs;
  final int fat;
  final String description;
  final Map<String, List<String>> meals;
  final List<String> tips;

  const DietPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.pref,
    required this.targetCal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.description,
    required this.meals,
    required this.tips,
  });
}
