import 'package:flutter/material.dart';
import '../theme.dart';

class LevelBadge extends StatelessWidget {
  final int level;
  final String label;

  const LevelBadge({super.key, required this.level, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: levelBg(level),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: levelColor(level), fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
