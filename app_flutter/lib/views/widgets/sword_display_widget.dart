import 'package:flutter/material.dart';

/// P2-31: 검 이름 + 강화 레벨 표시 공용 위젯
class SwordDisplayWidget extends StatelessWidget {
  final String name;
  final int level;
  final double? fontSize;

  const SwordDisplayWidget({
    super.key,
    required this.name,
    required this.level,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: (fontSize ?? 32),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '+$level',
          style: TextStyle(
            fontSize: (fontSize ?? 32) * 1.5,
            fontWeight: FontWeight.bold,
            color: getLevelColor(level),
          ),
        ),
      ],
    );
  }

  static Color getLevelColor(int level) {
    if (level >= 18) return Colors.white;
    if (level >= 15) return const Color(0xFFFFD700);
    if (level >= 10) return const Color(0xFF9C27B0);
    if (level >= 6) return const Color(0xFF2196F3);
    return Colors.grey[400]!;
  }
}
