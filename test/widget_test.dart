import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitforge/providers/app_provider.dart';
import 'package:fitforge/screens/progress_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Level personalization (#5)', () {
    test('sets scale by level and clamp to a sane minimum', () {
      expect(adjustedSets(4, 1), 3); // Noob: one fewer
      expect(adjustedSets(4, 2), 4); // Beginner: base
      expect(adjustedSets(4, 4), 5); // Advanced: one more
      expect(adjustedSets(4, 5), 6); // Expert: two more
      expect(adjustedSets(2, 1), 2); // never drops below 2
    });

    test('rest scales by level and clamps', () {
      expect(adjustedRest(60, 1), 80); // lower level rests longer
      expect(adjustedRest(60, 5), 40); // expert rests less
      expect(adjustedRest(30, 5), 20); // never below 20s
    });
  });

  group('Body metrics & calorie targets (#4)', () {
    test('BMR / TDEE / recommendation use Mifflin-St Jeor', () {
      final p = AppProvider();
      p.updateBodyMetrics(weightKg: 80, heightCm: 180, age: 30, sex: 'male', activity: 'Moderate');
      // 10*80 + 6.25*180 - 5*30 + 5 = 1780
      expect(p.bmr, closeTo(1780, 0.01));
      expect(p.tdee, closeTo(1780 * 1.55, 0.01)); // 2759
      // default goal "Build Muscle" => +300, rounded to nearest 10
      expect(p.recommendedCalories, 3060);
    });

    test('goal changes the calorie recommendation', () {
      final p = AppProvider();
      p.updateBodyMetrics(weightKg: 80, heightCm: 180, age: 30, sex: 'male', activity: 'Moderate');
      p.setSelectedGoal('Lose Fat');
      expect(p.recommendedCalories, 2360); // 2759 - 400 -> 2360
    });

    test('metrics absent => no derived values', () {
      final p = AppProvider();
      expect(p.hasBodyMetrics, isFalse);
      expect(p.bmr, isNull);
      expect(p.recommendedCalories, isNull);
    });

    test('invalid metrics are rejected', () {
      final p = AppProvider();
      p.updateBodyMetrics(weightKg: 5, heightCm: 5, age: 2);
      expect(p.hasBodyMetrics, isFalse);
    });
  });

  group('Workout history & streak (#3)', () {
    test('logging a workout starts a streak of 1', () {
      final p = AppProvider();
      expect(p.streak, 0);
      p.logWorkout(calories: 200);
      expect(p.totalWorkouts, 1);
      expect(p.streak, 1);
      expect(p.history.last['worked'], true);
    });
  });

  testWidgets('Progress screen shows empty state with no data', (tester) async {
    final p = AppProvider();
    await tester.pumpWidget(MaterialApp(
      home: ChangeNotifierProvider<AppProvider>.value(
        value: p,
        child: const Scaffold(body: ProgressScreen()),
      ),
    ));
    expect(find.text('No data yet'), findsOneWidget);
  });
}
