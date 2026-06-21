import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food.dart';
import '../models/diet_plan.dart';
import '../data/foods_data.dart';
import '../data/diet_plans_data.dart';

// ─── Level personalization (#5) ────────────────────────────────────────────────
// The same plan adapts to the user's fitness level: lower levels do fewer sets
// with longer rest, higher levels do more sets with shorter rest.
const Map<int, int> _setDelta = {1: -1, 2: 0, 3: 0, 4: 1, 5: 2};
const Map<int, int> _restDelta = {1: 20, 2: 0, 3: 0, 4: -15, 5: -20};

int adjustedSets(int baseSets, int level) =>
    (baseSets + (_setDelta[level] ?? 0)).clamp(2, 12);

int adjustedRest(int baseRest, int level) =>
    (baseRest + (_restDelta[level] ?? 0)).clamp(20, 600);

// ─── Body metrics (#4) ──────────────────────────────────────────────────────────
const Map<String, double> activityFactors = {
  'Sedentary': 1.2,
  'Light': 1.375,
  'Moderate': 1.55,
  'Active': 1.725,
  'Very Active': 1.9,
};

class AppProvider extends ChangeNotifier {
  int _userLevel = 2;
  int _calorieGoal = 2100;
  List<Food> _todayLog = [];
  DietPlan? _activeDietPlan;
  List<Map<String, dynamic>> _history = [];
  String _selectedGoal = "Build Muscle";
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  String? _selectedPlanType;
  String _userName = 'Athlete';
  int _reminderHour = 19;
  int _reminderMinute = 0;

  // Body metrics
  double? _weightKg;
  int? _heightCm;
  int? _age;
  String _sex = 'male'; // 'male' | 'female'
  String _activity = 'Moderate';
  List<Map<String, dynamic>> _weightLog = [];

  int get userLevel => _userLevel;
  int get calorieGoal => _calorieGoal;
  List<Food> get todayLog => List.unmodifiable(_todayLog);
  DietPlan? get activeDietPlan => _activeDietPlan;
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);
  String get selectedGoal => _selectedGoal;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String? get selectedPlanType => _selectedPlanType;
  String get userName => _userName;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;

  double? get weightKg => _weightKg;
  int? get heightCm => _heightCm;
  int? get age => _age;
  String get sex => _sex;
  String get activity => _activity;
  List<Map<String, dynamic>> get weightLog => List.unmodifiable(_weightLog);

  int get todayCalIn => _todayLog.fold(0, (a, f) => a + f.cal);
  int get todayProtein => _todayLog.fold(0, (a, f) => a + f.protein);
  int get todayCarbs => _todayLog.fold(0, (a, f) => a + f.carbs);
  int get todayFat => _todayLog.fold(0, (a, f) => a + f.fat);

  // Level-adjusted helpers for the active user.
  int setsForUser(int baseSets) => adjustedSets(baseSets, _userLevel);
  int restForUser(int baseRest) => adjustedRest(baseRest, _userLevel);

  // ── Body metric derived values (Mifflin-St Jeor) ──────────────────────────────
  bool get hasBodyMetrics => _weightKg != null && _heightCm != null && _age != null;

  double? get bmr {
    if (!hasBodyMetrics) return null;
    final base = 10 * _weightKg! + 6.25 * _heightCm! - 5 * _age!;
    return _sex == 'female' ? base - 161 : base + 5;
  }

  double? get tdee {
    final b = bmr;
    if (b == null) return null;
    return b * (activityFactors[_activity] ?? 1.55);
  }

  /// Suggested daily calories based on TDEE and the user's selected goal.
  int? get recommendedCalories {
    final t = tdee;
    if (t == null) return null;
    final adj = switch (_selectedGoal) {
      'Build Muscle' => 300,
      'Get Stronger' => 200,
      'Lose Fat' => -400,
      _ => 0,
    };
    return ((t + adj) / 10).round() * 10;
  }

  // ── Streak / stats (#3 — computed over real calendar days) ─────────────────────
  int get streak {
    if (_history.isEmpty) return 0;
    int i = _history.length - 1;
    // Today not done yet shouldn't break the streak — skip a trailing rest day
    // only if it is today.
    if (_history[i]['worked'] != true && _history[i]['date'] == _todayStr) i--;
    int s = 0;
    for (; i >= 0; i--) {
      if (_history[i]['worked'] == true) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }

  int get totalWorkouts => _history.where((d) => d['worked'] == true).length;

  int get weeklyCalsBurned => _history.length >= 7
      ? _history.sublist(_history.length - 7).fold(0, (a, d) => a + ((d['calories'] as int?) ?? 0))
      : _history.fold(0, (a, d) => a + ((d['calories'] as int?) ?? 0));

  int get avgDailyBurned => weeklyCalsBurned ~/ 7;

  static String get _todayStr => DateTime.now().toIso8601String().split('T')[0];
  static String _fmt(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String().split('T')[0];

  /// Fill in every calendar day between the first recorded day and today as a
  /// non-workout day, so streak / consistency / heatmap reflect real days off
  /// rather than only the days a workout was logged.
  void _backfillHistory() {
    if (_history.isEmpty) return;
    _history.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    final byDate = {for (final d in _history) d['date'] as String: d};
    final first = DateTime.parse(_history.first['date'] as String);
    final today = DateTime.parse(_todayStr);
    final filled = <Map<String, dynamic>>[];
    for (var day = first; !day.isAfter(today); day = day.add(const Duration(days: 1))) {
      final key = _fmt(day);
      filled.add(byDate[key] ?? {'date': key, 'worked': false, 'calories': 0});
    }
    _history = filled;
  }

  Future<void> load() async {
    try {
    final prefs = await SharedPreferences.getInstance();
    _userLevel = prefs.getInt('userLevel') ?? 2;
    _calorieGoal = prefs.getInt('calorieGoal') ?? 2100;
    _selectedGoal = prefs.getString('selectedGoal') ?? "Build Muscle";
    _notificationsEnabled = prefs.getBool('notifications') ?? true;
    _vibrationEnabled = prefs.getBool('vibration') ?? true;
    _selectedPlanType = prefs.getString('selectedPlanType');
    _userName = prefs.getString('userName') ?? 'Athlete';
    _reminderHour = prefs.getInt('reminderHour') ?? 19;
    _reminderMinute = prefs.getInt('reminderMinute') ?? 0;

    // Body metrics
    final w = prefs.getDouble('weightKg');
    _weightKg = (w != null && w > 0) ? w : null;
    final h = prefs.getInt('heightCm');
    _heightCm = (h != null && h > 0) ? h : null;
    final a = prefs.getInt('age');
    _age = (a != null && a > 0) ? a : null;
    _sex = prefs.getString('sex') ?? 'male';
    _activity = prefs.getString('activity') ?? 'Moderate';
    final weightLogJson = prefs.getString('weightLog');
    if (weightLogJson != null) {
      try {
        _weightLog = (jsonDecode(weightLogJson) as List)
            .map((m) => Map<String, dynamic>.from(m as Map))
            .where((d) => d.containsKey('date') && d.containsKey('weight'))
            .toList();
      } catch (_) {
        _weightLog = [];
      }
    }

    // Only restore today's food log if it was saved today
    final today = _todayStr;
    final logDate = prefs.getString('todayLogDate');
    if (logDate == today) {
      try {
        final logJson = prefs.getString('todayLog');
        if (logJson != null) {
          final List decoded = jsonDecode(logJson);
          _todayLog = decoded
              .map((m) => Food.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList();
        }
      } catch (_) {
        _todayLog = [];
      }
    } else {
      _todayLog = [];
    }

    final activePlanId = prefs.getString('activeDietPlanId');
    if (activePlanId != null && activePlanId.isNotEmpty) {
      try {
        _activeDietPlan = dietPlans.firstWhere((p) => p.id == activePlanId);
      } catch (_) {
        _activeDietPlan = null;
      }
    }

    final historyJson = prefs.getString('workoutHistory');
    if (historyJson != null) {
      try {
        final List decoded = jsonDecode(historyJson);
        _history = decoded
            .map((m) => Map<String, dynamic>.from(m))
            .where((d) => d.containsKey('date') && d.containsKey('worked') && d.containsKey('calories'))
            .toList();
      } catch (_) {
        _history = [];
      }
    } else {
      _history = [];
    }
    _backfillHistory();
    } catch (_) {
      // Prefs unavailable — run with defaults
    }
    notifyListeners();
  }

  void logWorkout({required int calories}) {
    final today = _todayStr;
    final idx = _history.indexWhere((d) => d['date'] == today);
    if (idx >= 0) {
      _history[idx] = {
        'date': today,
        'worked': true,
        'calories': ((_history[idx]['calories'] as int?) ?? 0) + calories,
      };
    } else {
      _history = [..._history, {'date': today, 'worked': true, 'calories': calories}];
    }
    _backfillHistory();
    _saveHistory();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('workoutHistory', jsonEncode(_history));
    } catch (_) {}
  }

  void setUserLevel(int level) {
    if (level < 1 || level > 5) return;
    _userLevel = level;
    _save();
    notifyListeners();
  }

  void setCalorieGoal(int goal) {
    if (goal < 500 || goal > 10000) return;
    _calorieGoal = goal;
    _save();
    notifyListeners();
  }

  void addFood(Food food) {
    _todayLog = [..._todayLog, food];
    _save();
    notifyListeners();
  }

  void removeFood(int index) {
    if (index < 0 || index >= _todayLog.length) return;
    final list = [..._todayLog];
    list.removeAt(index);
    _todayLog = list;
    _save();
    notifyListeners();
  }

  void setActiveDietPlan(DietPlan? plan) {
    _activeDietPlan = plan;
    if (plan != null) _calorieGoal = plan.targetCal;
    _save();
    notifyListeners();
  }

  void setSelectedGoal(String goal) {
    _selectedGoal = goal;
    _save();
    notifyListeners();
  }

  void toggleNotifications() {
    _notificationsEnabled = !_notificationsEnabled;
    _save();
    notifyListeners();
  }

  void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
    _save();
    notifyListeners();
  }

  void setUserName(String name) {
    final trimmed = name.trim();
    _userName = trimmed.isEmpty ? 'Athlete' : trimmed.substring(0, trimmed.length.clamp(0, 30));
    _save();
    notifyListeners();
  }

  void setSelectedPlanType(String? type) {
    _selectedPlanType = type;
    _save();
    notifyListeners();
  }

  void setReminderTime(int hour, int minute) {
    _reminderHour = hour.clamp(0, 23);
    _reminderMinute = minute.clamp(0, 59);
    _save();
    notifyListeners();
  }

  /// Update any subset of the user's body metrics. A changed weight is also
  /// appended to the weight log (one entry per calendar day).
  void updateBodyMetrics({double? weightKg, int? heightCm, int? age, String? sex, String? activity}) {
    if (weightKg != null && weightKg >= 20 && weightKg <= 400) {
      if (_weightKg != weightKg) _logWeight(weightKg);
      _weightKg = weightKg;
    }
    if (heightCm != null && heightCm >= 80 && heightCm <= 260) _heightCm = heightCm;
    if (age != null && age >= 10 && age <= 120) _age = age;
    if (sex != null && (sex == 'male' || sex == 'female')) _sex = sex;
    if (activity != null && activityFactors.containsKey(activity)) _activity = activity;
    _save();
    notifyListeners();
  }

  void _logWeight(double weight) {
    final today = _todayStr;
    final idx = _weightLog.indexWhere((d) => d['date'] == today);
    if (idx >= 0) {
      _weightLog[idx] = {'date': today, 'weight': weight};
    } else {
      _weightLog = [..._weightLog, {'date': today, 'weight': weight}];
    }
    _weightLog.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  /// Apply the TDEE-based recommendation to the daily calorie goal.
  void applyRecommendedCalories() {
    final rec = recommendedCalories;
    if (rec != null) setCalorieGoal(rec);
  }

  Food? findFood(String id) {
    try {
      return indianFoods.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userLevel', _userLevel);
      await prefs.setInt('calorieGoal', _calorieGoal);
      await prefs.setString('selectedGoal', _selectedGoal);
      await prefs.setBool('notifications', _notificationsEnabled);
      await prefs.setBool('vibration', _vibrationEnabled);
      if (_selectedPlanType != null) {
        await prefs.setString('selectedPlanType', _selectedPlanType!);
      } else {
        await prefs.remove('selectedPlanType');
      }
      await prefs.setString('userName', _userName);
      await prefs.setInt('reminderHour', _reminderHour);
      await prefs.setInt('reminderMinute', _reminderMinute);
      // Body metrics
      if (_weightKg != null) await prefs.setDouble('weightKg', _weightKg!);
      if (_heightCm != null) await prefs.setInt('heightCm', _heightCm!);
      if (_age != null) await prefs.setInt('age', _age!);
      await prefs.setString('sex', _sex);
      await prefs.setString('activity', _activity);
      await prefs.setString('weightLog', jsonEncode(_weightLog));
      final today = _todayStr;
      await prefs.setString('todayLogDate', today);
      await prefs.setString('todayLog', jsonEncode(_todayLog.map((f) => f.toMap()).toList()));
      await prefs.setString('activeDietPlanId', _activeDietPlan?.id ?? '');
    } catch (_) {}
  }
}
