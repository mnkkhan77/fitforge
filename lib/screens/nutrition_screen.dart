import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/food.dart';
import '../models/diet_plan.dart';
import '../data/foods_data.dart';
import '../data/diet_plans_data.dart';
import '../theme.dart';
import '../widgets/macro_bar.dart';

const _mealSections = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];

void _snack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    backgroundColor: const Color(0xFF1E1B4B),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    duration: const Duration(seconds: 2),
  ));
}

/// Lets the user pick a serving size before logging a food (#7).
void showAddFoodSheet(BuildContext context, Food food) {
  double qty = 1.0;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => StatefulBuilder(
      builder: (ctx, setSheet) {
        int scale(int v) => (v * qty).round();
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: surface2, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(food.name, style: const TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(food.source, style: const TextStyle(color: textMuted, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const Text('SERVINGS', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _QtyButton(icon: Icons.remove, onTap: () { if (qty > 0.5) setSheet(() => qty -= 0.5); }),
              SizedBox(
                width: 90,
                child: Text(qty == qty.roundToDouble() ? '${qty.toInt()}' : '$qty',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w900)),
              ),
              _QtyButton(icon: Icons.add, onTap: () { if (qty < 20) setSheet(() => qty += 0.5); }),
            ]),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _CalStat('kcal', scale(food.cal), green),
              _CalStat('Protein', scale(food.protein), indigoLight),
              _CalStat('Carbs', scale(food.carbs), amber),
              _CalStat('Fat', scale(food.fat), orange),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final logged = Food(
                    id: 'q${DateTime.now().millisecondsSinceEpoch}',
                    name: qty == 1.0 ? food.name : '${food.name} ×${qty == qty.roundToDouble() ? qty.toInt() : qty}',
                    category: food.category,
                    cal: scale(food.cal), protein: scale(food.protein),
                    carbs: scale(food.carbs), fat: scale(food.fat),
                    source: food.source,
                  );
                  context.read<AppProvider>().addFood(logged);
                  Navigator.pop(ctx);
                  _snack(context, '${logged.name} added to today\'s log');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: indigo, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Add to Log', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ]),
        );
      },
    ),
  );
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: indigo.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: indigo.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: indigoFaint, size: 22),
      ),
    );
  }
}

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _tab = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setTab(int index) {
    setState(() => _tab = index);
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: bg,
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NUTRITION', style: TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 14),
          Row(children: [
            _NutTab('📊 Tracker', 0, _tab, _setTab),
            _NutTab('🍽️ Log Food', 1, _tab, _setTab),
            _NutTab('🥗 Diet Plans', 2, _tab, _setTab),
          ]),
        ]),
      ),
      Expanded(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _tab = index),
          children: const [
            _TrackerTab(),
            _SearchTab(),
            _PlansTab(),
          ],
        ),
      ),
    ]);
  }
}

// TRACKER TAB
class _TrackerTab extends StatefulWidget {
  const _TrackerTab();

  @override
  State<_TrackerTab> createState() => _TrackerTabState();
}

class _TrackerTabState extends State<_TrackerTab> {
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    final p = Provider.of<AppProvider>(context, listen: false);
    _goalController = TextEditingController(text: '${p.calorieGoal}');
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final calLeft = p.calorieGoal - p.todayCalIn;
    final goalController = _goalController;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final todayBurned = p.history
        .where((d) => d['date'] == todayStr)
        .fold(0, (a, d) => a + ((d['calories'] as int?) ?? 0));

    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
      // Calorie ring
      Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF134E4A), Color(0xFF0F172A)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: teal.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          SizedBox(
            width: 130, height: 130,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 130, height: 130,
                child: CircularProgressIndicator(
                  value: (p.todayCalIn / p.calorieGoal).clamp(0.0, 1.0),
                  backgroundColor: surface,
                  valueColor: const AlwaysStoppedAnimation(teal),
                  strokeWidth: 12,
                )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${p.todayCalIn}', style: const TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w900)),
                Text('of ${p.calorieGoal}', style: const TextStyle(color: textMuted, fontSize: 10)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _CalStat('Eaten', p.todayCalIn, green),
            _CalStat(calLeft >= 0 ? 'Remaining' : 'Over', calLeft.abs(), calLeft >= 0 ? indigoLight : red),
            _CalStat('Burned', todayBurned, orange),
          ]),
        ]),
      ),

      // Macros
      Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Macronutrients', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          MacroBar(label: 'Protein', val: p.todayProtein, max: p.activeDietPlan?.protein ?? 150, color: indigoLight),
          MacroBar(label: 'Carbs', val: p.todayCarbs, max: p.activeDietPlan?.carbs ?? 250, color: amber),
          MacroBar(label: 'Fat', val: p.todayFat, max: p.activeDietPlan?.fat ?? 70, color: orange),
        ]),
      ),

      // Goal setter
      Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Daily Calorie Goal', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: goalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  filled: true, fillColor: bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: surface2)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: surface2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(goalController.text) ?? 0;
                FocusScope.of(context).unfocus();
                if (val < 500 || val > 10000) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Enter a value between 500 and 10,000 kcal',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    backgroundColor: red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    duration: const Duration(seconds: 2),
                  ));
                  return;
                }
                context.read<AppProvider>().setCalorieGoal(val);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Calorie goal updated to $val kcal',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFF1E1B4B),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  duration: const Duration(seconds: 2),
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Set'),
            ),
          ]),
        ]),
      ),

      // Food log
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Today's Food Log", style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          if (p.todayLog.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No meals logged yet.', style: TextStyle(color: textMuted, fontSize: 13))),
          ..._buildGroupedLog(context, p),
        ]),
      ),
    ]);
  }

  /// Group today's log by meal (Breakfast → Lunch → Snack → Dinner), preserving
  /// each item's original index so removal still targets the right entry (#7).
  List<Widget> _buildGroupedLog(BuildContext context, AppProvider p) {
    final widgets = <Widget>[];
    // Stable order: known meal sections first, then anything else.
    final order = [..._mealSections];
    for (final f in p.todayLog) {
      if (!order.contains(f.category)) order.add(f.category);
    }
    for (final section in order) {
      final items = p.todayLog.asMap().entries.where((e) => e.value.category == section).toList();
      if (items.isEmpty) continue;
      final subtotal = items.fold(0, (a, e) => a + e.value.cal);
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(section.toUpperCase(), style: const TextStyle(color: indigoLight, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          Text('$subtotal kcal', style: const TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ));
      for (final entry in items) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(entry.value.name, style: const TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Text('P:${entry.value.protein}g · C:${entry.value.carbs}g · F:${entry.value.fat}g',
                style: const TextStyle(color: textMuted, fontSize: 11)),
            ])),
            Text('${entry.value.cal} kcal', style: const TextStyle(color: indigoFaint, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => context.read<AppProvider>().removeFood(entry.key),
              child: const Text('✕', style: TextStyle(color: red, fontSize: 16)),
            ),
          ]),
        ));
      }
    }
    return widgets;
  }
}

class _CalStat extends StatelessWidget {
  final String label;
  final int val;
  final Color color;
  const _CalStat(this.label, this.val, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$val', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
    Text(label, style: const TextStyle(color: textMuted, fontSize: 11)),
  ]);
}

// SEARCH TAB
class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  String _search = '';
  bool _showManual = false;
  String _manualCat = 'Snack';
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _protCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _calCtrl.dispose();
    _protCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _search.length >= 2
      ? indianFoods.where((f) => f.name.toLowerCase().contains(_search.toLowerCase())).toList()
      : <Food>[];

    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
      TextField(
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(color: textPrimary),
        decoration: InputDecoration(
          hintText: '🔍  Search Indian foods...',
          hintStyle: const TextStyle(color: textMuted),
          filled: true, fillColor: surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: surface2)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: surface2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: indigo)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      const SizedBox(height: 16),

      if (_search.length < 2) ...[
        ..._mealSections.map((section) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(bottom: 10, top: 6),
            child: Text(section.toUpperCase(),
              style: const TextStyle(color: indigoLight, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1))),
          ...indianFoods.where((f) => f.category == section).take(4).map((food) => _FoodCard(food: food)),
          const SizedBox(height: 8),
        ])),
        GestureDetector(
          onTap: () => setState(() => _showManual = !_showManual),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: surface2, style: BorderStyle.solid, width: 2),
            ),
            child: const Center(child: Text('✏️ Enter manually', style: TextStyle(color: textMuted, fontSize: 14, fontWeight: FontWeight.w600))),
          ),
        ),
        if (_showManual) _ManualEntry(
          nameCtrl: _nameCtrl, calCtrl: _calCtrl, protCtrl: _protCtrl,
          carbCtrl: _carbCtrl, fatCtrl: _fatCtrl,
          category: _manualCat,
          onCategory: (c) => setState(() => _manualCat = c),
          onAdd: () {
            if (_nameCtrl.text.isEmpty || _calCtrl.text.isEmpty) return;
            final name = _nameCtrl.text;
            final food = Food(
              id: 'm${DateTime.now().millisecondsSinceEpoch}',
              name: name, category: _manualCat,
              cal: int.tryParse(_calCtrl.text) ?? 0,
              protein: int.tryParse(_protCtrl.text) ?? 0,
              carbs: int.tryParse(_carbCtrl.text) ?? 0,
              fat: int.tryParse(_fatCtrl.text) ?? 0,
              source: 'Manually entered',
            );
            context.read<AppProvider>().addFood(food);
            _snack(context, '$name added to today\'s log');
            _nameCtrl.clear(); _calCtrl.clear(); _protCtrl.clear(); _carbCtrl.clear(); _fatCtrl.clear();
            setState(() => _showManual = false);
          },
        ),
      ] else ...[
        if (results.isEmpty)
          Padding(padding: const EdgeInsets.only(top: 30),
            child: Center(child: Text('No results for "$_search"', style: const TextStyle(color: textMuted)))),
        ...results.map((food) => _FoodCard(food: food, large: true)),
      ],
    ]);
  }
}

class _FoodCard extends StatelessWidget {
  final Food food;
  final bool large;
  const _FoodCard({required this.food, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: surface2)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(food.name, style: TextStyle(color: textPrimary, fontSize: large ? 14 : 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(food.source, style: const TextStyle(color: textMuted, fontSize: 11)),
          Text('P:${food.protein}g · C:${food.carbs}g · F:${food.fat}g', style: const TextStyle(color: textMuted, fontSize: 11)),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${food.cal} kcal', style: const TextStyle(color: indigoFaint, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => showAddFoodSheet(context, food),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: indigo.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: indigo.withValues(alpha: 0.5)),
              ),
              child: const Text('+ Add', style: TextStyle(color: indigoFaint, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _ManualEntry extends StatelessWidget {
  final TextEditingController nameCtrl, calCtrl, protCtrl, carbCtrl, fatCtrl;
  final String category;
  final ValueChanged<String> onCategory;
  final VoidCallback onAdd;
  const _ManualEntry({required this.nameCtrl, required this.calCtrl, required this.protCtrl, required this.carbCtrl, required this.fatCtrl, required this.category, required this.onCategory, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: surface2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('MEAL', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
        Wrap(spacing: 6, runSpacing: 6, children: _mealSections.map((m) {
          final active = m == category;
          return GestureDetector(
            onTap: () => onCategory(m),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: active ? indigo.withValues(alpha: 0.2) : bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? indigo : surface2),
              ),
              child: Text(m, style: TextStyle(color: active ? indigoFaint : textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          );
        }).toList()),
        const SizedBox(height: 12),
        ...[
          [nameCtrl, 'Food name', TextInputType.text],
          [calCtrl, 'Calories', TextInputType.number],
          [protCtrl, 'Protein (g)', TextInputType.number],
          [carbCtrl, 'Carbs (g)', TextInputType.number],
          [fatCtrl, 'Fat (g)', TextInputType.number],
        ].map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: row[0] as TextEditingController,
            keyboardType: row[2] as TextInputType,
            style: const TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: row[1] as String,
              hintStyle: const TextStyle(color: textMuted),
              filled: true, fillColor: bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: surface2)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: surface2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        )),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Add Food', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}

// PLANS TAB
class _PlansTab extends StatefulWidget {
  const _PlansTab();

  @override
  State<_PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<_PlansTab> {
  String _goal = 'Muscle Gain';
  String _pref = 'Vegetarian';

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final filtered = dietPlans.where((d) => d.goal == _goal && d.pref == _pref).toList();

    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), children: [
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: surface2)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your Goal', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: ['Muscle Gain', 'Fat Loss', 'Maintain'].map((g) =>
            _SelectChip(g, _goal, (v) => setState(() => _goal = v))).toList()),
          const SizedBox(height: 14),
          const Text('Preference', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(children: ['Vegetarian', 'Non-Vegetarian', 'Vegan'].map((pr) =>
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _SelectChip(pr, _pref, (v) => setState(() => _pref = v))))).toList()),
        ]),
      ),
      if (filtered.isEmpty)
        const Center(child: Padding(padding: EdgeInsets.only(top: 40), child: Column(children: [
          Text('🥗', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text('No plan for this combo.', style: TextStyle(color: textMuted)),
        ]))),
      ...filtered.map((plan) => _DietPlanCard(plan: plan, isActive: p.activeDietPlan?.id == plan.id)),
    ]);
  }
}

class _SelectChip extends StatelessWidget {
  final String label, current;
  final ValueChanged<String> onTap;
  const _SelectChip(this.label, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = label == current;
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? indigo.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? indigo : surface2),
        ),
        child: Center(child: Text(label,
          style: TextStyle(color: active ? indigoFaint : textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
      ),
    );
  }
}

class _DietPlanCard extends StatelessWidget {
  final DietPlan plan;
  final bool isActive;
  const _DietPlanCard({required this.plan, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? indigo : surface2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan.name, style: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(plan.description, style: const TextStyle(color: textSecondary, fontSize: 13)),
          ])),
          if (isActive) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: indigo.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
            child: const Text('Active', style: TextStyle(color: indigoFaint, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          _MacroChip('${plan.targetCal}', 'kcal', green),
          const SizedBox(width: 8),
          _MacroChip('${plan.protein}g', 'Protein', indigoLight),
          const SizedBox(width: 8),
          _MacroChip('${plan.carbs}g', 'Carbs', amber),
          const SizedBox(width: 8),
          _MacroChip('${plan.fat}g', 'Fat', orange),
        ]),
        const SizedBox(height: 14),
        ...['breakfast', 'lunch', 'snack', 'dinner'].map((meal) {
          final foods = (plan.meals[meal] ?? [])
            .map((id) => indianFoods.firstWhere((f) => f.id == id, orElse: () => indianFoods[0]))
            .toList();
          final mealCal = foods.fold(0, (a, f) => a + f.cal);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(meal[0].toUpperCase() + meal.substring(1),
                  style: const TextStyle(color: indigoLight, fontSize: 12, fontWeight: FontWeight.w700)),
                Text('$mealCal kcal', style: const TextStyle(color: textMuted, fontSize: 12)),
              ]),
              const SizedBox(height: 3),
              Text(foods.map((f) => f.name).join(' · '), style: const TextStyle(color: textSecondary, fontSize: 12)),
            ]),
          );
        }),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: amber.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡 Tips', style: TextStyle(color: amber, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...plan.tips.map((t) => Text('• $t', style: const TextStyle(color: textSecondary, fontSize: 12))),
          ]),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final prov = context.read<AppProvider>();
              prov.setActiveDietPlan(isActive ? null : plan);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? red.withValues(alpha: 0.2) : indigo,
              foregroundColor: isActive ? red : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isActive ? BorderSide(color: red.withValues(alpha: 0.4)) : BorderSide.none,
              ),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: Text(isActive ? 'Deactivate Plan' : 'Activate This Plan',
              style: TextStyle(color: isActive ? const Color(0xFFFCA5A5) : Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ]),
    );
  }
}

class _NutTab extends StatelessWidget {
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;
  const _NutTab(this.label, this.index, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 10, 16, 0),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: active ? indigo : Colors.transparent, width: 2)),
        ),
        child: Text(label, style: TextStyle(color: active ? indigoFaint : textMuted, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _MacroChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label, style: const TextStyle(color: textMuted, fontSize: 10)),
        ]),
      ),
    );
  }
}
