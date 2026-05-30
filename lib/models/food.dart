class Food {
  final String id;
  final String name;
  final String category;
  final int cal;
  final int protein;
  final int carbs;
  final int fat;
  final String source;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.cal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.source,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'category': category,
    'cal': cal, 'protein': protein, 'carbs': carbs, 'fat': fat, 'source': source,
  };

  factory Food.fromMap(Map<String, dynamic> m) => Food(
    id: m['id'], name: m['name'], category: m['category'],
    cal: m['cal'], protein: m['protein'], carbs: m['carbs'],
    fat: m['fat'], source: m['source'],
  );
}
