import 'package:flutter/material.dart';

/// 강화 연출을 렌더링하는 위젯 (P1: 최소한의 텍스트 연출)
class EnhanceAnimationWidget extends StatelessWidget {
  final String text;
  final Color color;
  final bool visible;

  const EnhanceAnimationWidget({
    super.key,
    required this.text,
    required this.color,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
