import 'package:flutter/material.dart';
import 'screens/start_screen.dart';
import 'screens/game_screen_.dart'  ;
import 'screens/result_screen.dart';
import 'screens/pause_menu.dart';

void main() => runApp(const BubblePopApp());

class BubblePopApp extends StatelessWidget {
  const BubblePopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Pop',
      theme: ThemeData.dark(),
      home: const StartScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/game': (_) => const GameScreen(),
        '/pause': (_) => const PauseMenu(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/result') {
          final args = settings.arguments as Map<String, int>? ?? {};
          final score = args['score'] ?? 0;
          final highScore = args['highScore'] ?? 0;
          return MaterialPageRoute(
            builder: (_) => ResultScreen(score: score, highScore: highScore),
          );
        }
        return null;
      },
    );
  }
}