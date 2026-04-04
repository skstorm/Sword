import 'package:flutter/material.dart';
import 'enhance_view.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    EnhanceView(),
    _PlaceholderView(title: '공방'),
    _PlaceholderView(title: '업적'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.grey[850],
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey[400],
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.construction),
            label: '대장간',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warehouse),
            label: '공방',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: '업적',
          ),
        ],
      ),
    );
  }
}

class _PlaceholderView extends StatelessWidget {
  final String title;
  const _PlaceholderView({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        title: Text(title, style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          '준비 중',
          style: TextStyle(fontSize: 24, color: Colors.grey[600]),
        ),
      ),
    );
  }
}
