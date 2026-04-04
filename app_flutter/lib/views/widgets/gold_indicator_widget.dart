import 'package:flutter/material.dart';

/// P2-31: 골드 + 파편 표시 공용 위젯
class GoldIndicatorWidget extends StatelessWidget {
  final int gold;
  final int fragments;

  const GoldIndicatorWidget({
    super.key,
    required this.gold,
    required this.fragments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
          const SizedBox(width: 8),
          Text(
            '$gold',
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
          const SizedBox(width: 24),
          Icon(Icons.diamond, color: Colors.cyan[300], size: 24),
          const SizedBox(width: 8),
          Text(
            '$fragments',
            style: const TextStyle(fontSize: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
