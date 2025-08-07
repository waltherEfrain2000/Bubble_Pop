import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/bubble.dart';
import '../models/game_stats.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameController {
  List<Bubble> bubbles = [];
  final Random random = Random();
  final AudioPlayer popPlayer = AudioPlayer();
  final AudioPlayer musicPlayer = AudioPlayer();
  final AudioPlayer spawnPlayer = AudioPlayer();
  final AudioPlayer bonusPlayer = AudioPlayer(); // Para sonido de vida extra
  int score = 0;
  int highScore = 0;
  int bubblesPopped = 0;
  int bubblesMissed = 0;
  int maxLives = 5; // Más vidas máximas para facilitar
  int currentLives = 5; // Más vidas iniciales
  int baseSpeed = 4500; // Más lento (era 3500)
  int baseInterval = 1800; // Más lento (era 1200)
  bool isRunning = false;
  bool isPaused = false;

  // Sistema de vidas extra (más fácil de conseguir)
  int nextLifeAt = 30; // Próxima vida a los 30 puntos (era 50)
  int lifeIncrement = 60; // Cada 60 puntos (era 100)

  // Sistema de power-ups (más frecuentes)
  int nextPowerUpAt = 20; // Próximo power-up a las 20 burbujas (era 25)
  int powerUpIncrement = 20; // Cada 20 burbujas (era 25)
  bool powerUpActive = false; // Si hay un power-up activo
  int powerUpDuration = 15000; // Duración en ms (15 segundos, era 10)
  DateTime? powerUpStartTime; // Cuando empezó el power-up

  // Nuevas variables para estadísticas
  GameStats gameStats = GameStats();

  final VoidCallback onUpdate;
  final Function(int score, int highScore) onGameOver;

  GameController({
    required this.onUpdate,
    required this.onGameOver,
  });

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();

    // Cargar estadísticas del juego
    String? statsJson = prefs.getString('gameStats');
    if (statsJson != null) {
      gameStats = GameStats.fromJson(json.decode(statsJson));
      highScore = gameStats.highScore;
    } else {
      highScore = prefs.getInt('highScore') ?? 0;
      gameStats = GameStats(highScore: highScore);
    }
    onUpdate();
  }

  Future<void> saveGameStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gameStats', json.encode(gameStats.toJson()));
  }

  void checkPowerUpExpiry() {
    if (powerUpActive && powerUpStartTime != null) {
      final elapsed =
          DateTime.now().difference(powerUpStartTime!).inMilliseconds;
      if (elapsed >= powerUpDuration) {
        powerUpActive = false;
        powerUpStartTime = null;
        onUpdate(); // Actualizar UI
      }
    }
  }

  void activatePowerUp() async {
    powerUpActive = true;
    powerUpStartTime = DateTime.now();
    nextPowerUpAt += powerUpIncrement;

    // Sonido especial para power-up
    await bonusPlayer.play(AssetSource('sounds/bubble_spawn.mp3'));
    onUpdate(); // Actualizar UI inmediatamente

    // Programar desactivación automática
    Future.delayed(Duration(milliseconds: powerUpDuration), () {
      if (powerUpActive && powerUpStartTime != null) {
        final elapsed =
            DateTime.now().difference(powerUpStartTime!).inMilliseconds;
        if (elapsed >= powerUpDuration) {
          powerUpActive = false;
          powerUpStartTime = null;
          onUpdate();
        }
      }
    });
  }

  Future<void> updateHighScore() async {
    if (score > highScore) {
      highScore = score;
      gameStats.highScore = highScore;
    }
    onUpdate();
  }

  Future<void> saveGameEndStats() async {
    // Solo actualizar estadísticas al final del juego
    gameStats.totalBubblesPopped += bubblesPopped;
    gameStats.totalGamesPlayed += 1;
    gameStats.gameHistory.add(score);
    gameStats.lastPlayed = DateTime.now();

    // Mantener solo los últimos 50 juegos en el historial
    if (gameStats.gameHistory.length > 50) {
      gameStats.gameHistory =
          gameStats.gameHistory.sublist(gameStats.gameHistory.length - 50);
    }

    await saveGameStats();
    onUpdate();
  }

  void start(BuildContext context) async {
    isRunning = true;
    isPaused = false;
    await loadHighScore();
    score = 0;
    bubblesPopped = 0;
    bubblesMissed = 0;
    currentLives = maxLives; // Resetear vidas
    nextLifeAt = 30; // Resetear contador de próxima vida
    nextPowerUpAt = 20; // Resetear contador de próximo power-up (era 25)
    powerUpActive = false; // Resetear power-up
    powerUpStartTime = null;
    bubbles.clear();
    // await musicPlayer.play(
    //   AssetSource('sounds/music.mp3'),
    //   volume: 0.4,
    //   loopMode: LoopMode.all,
    // );
    onUpdate();
    _spawnLoop(context);
  }

  void _spawnLoop(BuildContext context) async {
    while (isRunning) {
      // Solo continuar si no está pausado
      if (isPaused) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      // Verificar si el power-up ha expirado
      checkPowerUpExpiry();

      // Aplicar efectos del power-up (reducir dificultad)
      int difficultyMultiplier =
          powerUpActive ? 2 : 1; // Más lento cuando hay power-up
      int interval = (baseInterval - min(bubblesPopped * 3, 800))
          .clamp(300, baseInterval)
          .toInt();
      interval *= difficultyMultiplier; // Duplicar intervalo si hay power-up

      await Future.delayed(Duration(milliseconds: interval));

      // Verificar nuevamente si no está pausado antes de crear burbujas
      if (!isRunning || isPaused) continue;

      // Menos burbujas durante power-up
      int bubblesThisCycle = powerUpActive
          ? 1 // Solo 1 burbuja durante power-up
          : 1 + (bubblesPopped ~/ 15);

      for (int i = 0; i < bubblesThisCycle; i++) {
        if (!isRunning || isPaused) break; // Verificar en cada iteración

        double posX =
            random.nextDouble() * (MediaQuery.of(context).size.width - 80);
        int speed = (baseSpeed - min(bubblesPopped * 15, 2000))
            .clamp(1000, baseSpeed)
            .toInt();

        // Burbujas más lentas durante power-up
        if (powerUpActive) {
          speed = (speed * 2.0).toInt(); // 100% más lentas (era 50%)
        }

        // Determinar si crear burbuja especial (mayor probabilidad durante power-up)
        double specialChance =
            powerUpActive ? 0.25 : 0.08; // 25% vs 8% (era 15% vs 5%)
        bool shouldCreateSpecial = bubblesPopped > 5 &&
            random.nextDouble() < specialChance; // Desde 5 burbujas (era 10)

        List<String> bubbleImages = [
          'assets/images/bubble1.png',
          'assets/images/bubble2.png',
          'assets/images/bubble3.png'
        ];
        String img = bubbleImages[random.nextInt(bubbleImages.length)];
        double size = 70 +
            random.nextDouble() * 60; // Burbujas aún más grandes (era 60 + 50)

        // Si es especial, hacer la burbuja dorada y más grande
        if (shouldCreateSpecial) {
          size = 90 +
              random.nextDouble() *
                  40; // Burbujas especiales más grandes (era 80 + 30)
        }

        bubbles.add(Bubble(
          position: Offset(posX, 0),
          size: size,
          speed: speed *
              (shouldCreateSpecial ? 1.5 : 1)
                  .toInt(), // Burbujas especiales más lentas
          key: UniqueKey(),
          image: img,
          isSpecial: shouldCreateSpecial,
          specialType: shouldCreateSpecial ? 'life' : 'normal',
        ));

        if (!isPaused) {
          await spawnPlayer.play(AssetSource('sounds/bubble_spawn.mp3'),
              volume: 0.2);
        }
      }
      onUpdate();
    }
  }

  void popBubble(Bubble bubble) async {
    bubbles.removeWhere((b) => b.key == bubble.key);

    // Si es una burbuja especial, dar vida extra
    if (bubble.isSpecial && bubble.specialType == 'life' && currentLives < 5) {
      currentLives += 1;
      score += 5; // Bonus de puntos por burbuja especial
      await bonusPlayer.play(AssetSource('sounds/bubble_spawn.mp3'));
      onUpdate(); // Actualizar UI inmediatamente
    } else {
      score += 1;
    }

    bubblesPopped += 1;

    // Verificar si activar power-up por burbujas reventadas
    if (bubblesPopped >= nextPowerUpAt && !powerUpActive) {
      activatePowerUp();
    }

    // Verificar si el jugador merece una vida extra por puntos
    if (score >= nextLifeAt && currentLives < 7) {
      // Máximo 7 vidas (era 5)
      currentLives += 1;
      nextLifeAt += lifeIncrement;
      await bonusPlayer.play(AssetSource('sounds/bubble_spawn.mp3'));
      onUpdate(); // Actualizar UI para mostrar la vida extra
    }

    onUpdate();
    await updateHighScore();
    await popPlayer.play(AssetSource('sounds/pop.mp3'));
  }

  void removeBubbleWithoutSound(Bubble bubble) {
    // Solo remover burbuja si el juego está corriendo y no pausado
    if (!isRunning || isPaused) return;

    bubbles.removeWhere((b) => b.key == bubble.key);
    bubblesMissed += 1;
    currentLives -= 1; // Perder una vida en lugar de contar missed
    onUpdate();

    if (currentLives <= 0) {
      // Game over cuando no hay vidas
      isRunning = false;
      isPaused = false;
      musicPlayer.stop();
      // Llamar saveGameEndStats solo al final del juego
      saveGameEndStats().then((_) => onGameOver(score, highScore));
    }
  }

  void pauseGame() {
    isPaused = true;
    musicPlayer.pause();
    onUpdate(); // Actualizar UI para mostrar estado pausado
  }

  void resumeGame(BuildContext context) {
    if (isPaused && isRunning) {
      isPaused = false;
      musicPlayer.resume();
      onUpdate(); // Actualizar UI para mostrar estado reanudado
    }
  }

  void dispose() {
    isRunning = false;
    isPaused = false;
    popPlayer.dispose();
    musicPlayer.dispose();
    spawnPlayer.dispose();
    bonusPlayer.dispose();
  }
}
