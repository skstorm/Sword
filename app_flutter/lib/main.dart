import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/title_view.dart';
import 'views/main_shell.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _gameStarted = false;

  void _startGame() {
    setState(() {
      _gameStarted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '검강화',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: _gameStarted ? const MainShell() : TitleView(onStart: _startGame),
    );
  }
}
