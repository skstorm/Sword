import 'package:flutter/material.dart';

class TitleView extends StatelessWidget {
  final VoidCallback onStart;
  const TitleView({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('⚔️', style: TextStyle(fontSize: 80)),
            SizedBox(height: 20),
            Text(
              '검강화',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '대장장이 시뮬레이터',
              style: TextStyle(fontSize: 18, color: Colors.grey[400]),
            ),
            SizedBox(height: 60),
            ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              child: Text('게임 시작'),
            ),
          ],
        ),
      ),
    );
  }
}
