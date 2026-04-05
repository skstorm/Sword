import 'package:flutter/material.dart';

/// 강화하기 / 판매하기 / 수집하기 액션 버튼 영역
class ActionButtonsWidget extends StatelessWidget {
  final bool isAnimating;
  final bool canEnhance;
  final bool canSell;
  final bool canCollect;
  final VoidCallback onEnhance;
  final VoidCallback onSell;
  final VoidCallback onCollect;

  const ActionButtonsWidget({
    super.key,
    required this.isAnimating,
    required this.canEnhance,
    required this.canSell,
    required this.canCollect,
    required this.onEnhance,
    required this.onSell,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton(
          onPressed: (isAnimating || !canEnhance) ? null : onEnhance,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: const Text('강화하기'),
        ),
        ElevatedButton(
          onPressed: (isAnimating || !canSell) ? null : onSell,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: const Text('판매하기'),
        ),
        if (canCollect)
          ElevatedButton(
            onPressed: isAnimating ? null : onCollect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: const Text('수집하기'),
          ),
      ],
    );
  }
}
