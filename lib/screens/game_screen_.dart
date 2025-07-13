import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../widgets/bubble_widget.dart';
import 'result_screen.dart';
import 'pause_menu.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameController controller;

  @override
  void initState() {
    super.initState();
    controller = GameController(
      onUpdate: () => setState(() {}),
      onGameOver: (score, highScore) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(score: score, highScore: highScore),
          ),
        );
      },
    );
    controller.start(context);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _pauseGame() {
    controller.pauseGame();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PauseMenu(
          onContinue: () {
            Navigator.pop(context);
            controller.resumeGame(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xffaeefff), Color(0xffeef9ff)],
          ),
        ),
        child: Stack(
          children: [
            ...controller.bubbles.map((bubble) => BubbleWidget(
                  key: bubble.key,
                  bubble: bubble,
                  onPop: () => controller.popBubble(bubble),
                  onRemoveWithoutSound: () => controller.removeBubbleWithoutSound(bubble),
                )),
            // Puntaje y pausa
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score: ${controller.score}',
                        style: const TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black12,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        )),
                    Row(
                      children: [
                        const Text('⭐',
                            style: TextStyle(fontSize: 22, color: Colors.yellowAccent)),
                        const SizedBox(width: 6),
                        Text('Best: ${controller.highScore}',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                    Row(
                      children: List.generate(3, (i) {
                        return Icon(
                          Icons.favorite,
                          color: (i < 3 - controller.bubblesMissed) ? Colors.red : Colors.grey,
                          size: 24,
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
           
            // Botón Pausa
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.pause, color: Colors.white, size: 36),
                onPressed: _pauseGame,
              ),
            ),
          ],
        ),
      ),
    );
  }
}