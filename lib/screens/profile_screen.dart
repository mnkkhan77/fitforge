import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _editName(BuildContext context, AppProvider p) {
    String draft = p.userName == 'Athlete' ? '' : p.userName;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        title: const Text('Your Name', style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700)),
        content: TextFormField(
          initialValue: draft,
          autofocus: true,
          onChanged: (v) => draft = v,
          style: const TextStyle(color: textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: textMuted),
            filled: true, fillColor: bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: surface2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: surface2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: indigo)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: textMuted))),
          TextButton(
            onPressed: () { p.setUserName(draft); Navigator.pop(context); },
            child: const Text('Save', style: TextStyle(color: indigo, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final levelNames = ['Noob','Beginner','Intermediate','Advanced','Expert'];

    return ListView(padding: const EdgeInsets.only(bottom: 100), children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 30),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)]),
        ),
        child: Row(children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [indigo, Color(0xFF8B5CF6)]),
            ),
            child: const Center(child: Text('🏋️', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => _editName(context, p),
                child: Row(children: [
                  Flexible(child: Text(p.userName,
                    style: const TextStyle(color: textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, color: textMuted, size: 15),
                ]),
              ),
              Text('${levelNames[(p.userLevel - 1).clamp(0, 4)]} · ${p.totalWorkouts} workouts completed',
                style: const TextStyle(color: indigoLight, fontSize: 14)),
            ]),
          ),
        ]),
      ),

      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(children: [
          // Level selector
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🎯 Your Fitness Level', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              ...levelNames.asMap().entries.map((e) {
                final isSelected = p.userLevel == e.key + 1;
                return GestureDetector(
                  onTap: () => p.setUserLevel(e.key + 1),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? indigo.withOpacity(0.15) : bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? indigo : surface2),
                    ),
                    child: Row(children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: levelColor(e.key + 1))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.value, style: TextStyle(color: isSelected ? indigoFaint : textSecondary, fontWeight: FontWeight.w600, fontSize: 14))),
                      if (isSelected) const Icon(Icons.check, color: indigo, size: 18),
                    ]),
                  ),
                );
              }),
            ]),
          ),

          // Goal selector
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🏆 Your Goal', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: ['Build Muscle','Lose Fat','Get Stronger','Improve Endurance','Stay Active'].map((g) {
                final active = p.selectedGoal == g;
                return GestureDetector(
                  onTap: () => p.setSelectedGoal(g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? indigo.withOpacity(0.2) : bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? indigo : surface2),
                    ),
                    child: Text(g, style: TextStyle(color: active ? indigoFaint : textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList()),
            ]),
          ),

          // Settings
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: surface2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('⚙️ Settings', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Workout Reminders', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Daily push notifications', style: TextStyle(color: textMuted, fontSize: 12)),
                ]),
                GestureDetector(
                  onTap: () => p.toggleNotifications(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48, height: 26,
                    decoration: BoxDecoration(
                      color: p.notificationsEnabled ? indigo : surface2,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: p.notificationsEnabled ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20, height: 20, margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ]),
              const Divider(color: surface2, height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Vibration & Sound', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Haptic feedback during workouts', style: TextStyle(color: textMuted, fontSize: 12)),
                ]),
                GestureDetector(
                  onTap: () => p.toggleVibration(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48, height: 26,
                    decoration: BoxDecoration(
                      color: p.vibrationEnabled ? indigo : surface2,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: p.vibrationEnabled ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 20, height: 20, margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ),
              ]),
              const Divider(color: surface2, height: 24),
              const Text('FitForge v2.0 · Built for India 🇮🇳', style: TextStyle(color: textMuted, fontSize: 13)),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
