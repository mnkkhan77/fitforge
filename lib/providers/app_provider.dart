import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food.dart';
import '../models/diet_plan.dart';
import '../data/foods_data.dart';
import '../data/diet_plans_data.dart';

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

  int get todayCalIn => _todayLog.fold(0, (a, f) => a + f.cal);
  int get todayProtein => _todayLog.fold(0, (a, f) => a + f.protein);
  int get todayCarbs => _todayLog.fold(0, (a, f) => a + f.carbs);
  int get todayFat => _todayLog.fold(0, (a, f) => a + f.fat);

  int get streak {
    int s = 0;
    for (int i = _history.length - 1; i >= 0; i--) {
      if (_history[i]['worked'] == true) s++; else break;
    }
    return s;
  }

  int get totalWorkouts => _history.where((d) => d['worked'] == true).length;

  int get weeklyCalsBurned =>
      _history.length >= 7
          ? _history.sublist(_history.length - 7).fold(0, (a, d) => a + ((d['calories'] as int?) ?? 0))
          : _history.fold(0, (a, d) => a + ((d['calories'] as int?) ?? 0));

  int get avgDailyBurned => weeklyCalsBurned ~/ 7;

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

    // Only restore today's food log if it was saved today
    final today = DateTime.now().toIso8601String().split('T')[0];
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
    } catch (_) {
      // Prefs unavailable — run with defaults
    }
    notifyListeners();
  }

  void logWorkout({required int calories}) {
    final today = DateTime.now().toIso8601String().split('T')[0];
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
      }
      await prefs.setString('userName', _userName);
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('todayLogDate', today);
      await prefs.setString('todayLog', jsonEncode(_todayLog.map((f) => f.toMap()).toList()));
      await prefs.setString('activeDietPlanId', _activeDietPlan?.id ?? '');
    } catch (_) {}
  }
}
