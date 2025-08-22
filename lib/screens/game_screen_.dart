import 'package:flutter/material.dart';
import '../game/game_controller.dart';
import '../widgets/bubble_widget.dart';
import 'result_screen.dart';
import 'pause_menu.dart';
import '../widgets/admob_banner.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late GameController controller;
  bool showLifeNotification = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addObserver(this); // Escuchar cambios de estado de la app
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
    WidgetsBinding.instance.removeObserver(this); // Remover observer
    controller.dispose();
    super.dispose();
  }

  // Detectar cuando la app va a segundo plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App en segundo plano o cerrada - pausar juego
        if (controller.isRunning && !controller.isPaused) {
          controller.pauseGame();
        }
        break;
      case AppLifecycleState.resumed:
        // App regresó al primer plano - NO reanudar automáticamente
        // El usuario debe presionar continuar manualmente
        break;
      case AppLifecycleState.hidden:
        // App oculta pero aún en memoria
        if (controller.isRunning && !controller.isPaused) {
          controller.pauseGame();
        }
        break;
    }
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: controller.powerUpActive
                ? [
                    const Color(0xff8e44ad)
                        .withOpacity(0.3), // Púrpura durante power-up
                    const Color(0xff9b59b6).withOpacity(0.3),
                    const Color(0xffaeefff),
                  ]
                : [const Color(0xffaeefff), const Color(0xffeef9ff)],
          ),
        ),
        child: Stack(
          children: [
            ...controller.bubbles.map((bubble) => BubbleWidget(
                  key: bubble.key,
                  bubble: bubble,
                  isPaused: controller.isPaused, // Pasar estado de pausa
                  onPop: () => controller.popBubble(bubble),
                  onRemoveWithoutSound: () =>
                      controller.removeBubbleWithoutSound(bubble),
                )),
            // Puntaje y pausa
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    Text('Burbujas: ${controller.bubblesPopped}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        )),
                    Text('Próxima vida: ${controller.nextLifeAt}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        )),
                    // Indicador de power-up
                    if (controller.powerUpActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '💖 POWER-UP ACTIVO',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Próxima vida: ${controller.nextLifeBubbleAt}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              )),
                          Text('Próximo slow: ${controller.nextSlowBubbleAt}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    Row(
                      children: [
                        const Text('⭐',
                            style: TextStyle(
                                fontSize: 22, color: Colors.yellowAccent)),
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
                      children: List.generate(7, (i) {
                        // Mostrar hasta 7 vidas (era 5)
                        return Icon(
                          Icons.favorite,
                          color: (i < controller.currentLives)
                              ? Colors.red
                              : Colors.grey.withOpacity(0.3),
                          size: 20, // Más pequeñas para que quepan (era 24)
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
      bottomNavigationBar: const AdmobBanner(), // <- ¡Banner aquí!
    );
  }
}
