import 'package:flutter/material.dart';
import '../theme.dart';

class MacroBar extends StatelessWidget {
  final String label;
  final int val;
  final int max;
  final Color color;

  const MacroBar({super.key, required this.label, required this.val, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: textSecondary, fontSize: 12)),
          Text('${val}g', style: const TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (val / max).clamp(0.0, 1.0),
            backgroundColor: bg,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }
}
