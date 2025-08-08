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
  int baseSpeed = 6000; // Mucho más lento al principio (era 4500)
  int baseInterval =
      2500; // Intervalo más largo para mejor distribución (era 1800)
  bool isRunning = false;
  bool isPaused = false;

  // Sistema anti-amontonamiento mejorado
  final List<Offset> _recentPositions = [];
  final double _minDistance =
      120.0; // Distancia mínima aumentada para evitar pegado visual
  double _screenWidth = 400.0; // Ancho por defecto
  int _lastUsedZone = -1; // Para alternar zonas

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

  // Configurar el tamaño de pantalla
  void setScreenSize(double width) {
    _screenWidth = width;
  }

  // Generar posición única sin superposición usando más zonas y tamaños reales
  Offset _generateUniquePosition(double bubbleSize) {
    const int totalZones = 8; // Más zonas para mejor distribución
    const int maxAttempts = 30; // Más intentos

    // Usar la mitad del tamaño de la burbuja como radio de seguridad
    double safetyRadius = bubbleSize / 2;
    double minDistanceForSize = _minDistance + safetyRadius;

    // Intentar usar zona diferente a la anterior
    int startZone = (_lastUsedZone + 1) % totalZones;

    for (int zoneOffset = 0; zoneOffset < totalZones; zoneOffset++) {
      int currentZone = (startZone + zoneOffset) % totalZones;

      for (int attempt = 0; attempt < maxAttempts ~/ totalZones; attempt++) {
        // Calcular límites de la zona considerando el tamaño de la burbuja
        double zoneWidth = _screenWidth / totalZones;
        double zoneStartX = currentZone * zoneWidth;
        double zoneEndX = zoneStartX + zoneWidth - bubbleSize;

        if (zoneEndX <= zoneStartX) continue; // Zona muy pequeña

        // Generar posición en esta zona
        double x = zoneStartX + random.nextDouble() * (zoneEndX - zoneStartX);
        final Offset newPosition = Offset(x, 0);

        // Verificar si la posición está libre considerando el tamaño
        bool isPositionFree = true;
        for (final recentPos in _recentPositions) {
          final double distance = (newPosition - recentPos).distance;
          if (distance < minDistanceForSize) {
            isPositionFree = false;
            break;
          }
        }

        // Verificar también con burbujas existentes usando sus tamaños reales
        if (isPositionFree) {
          for (final bubble in bubbles) {
            final double distance = (newPosition - bubble.position).distance;
            double requiredDistance = minDistanceForSize + (bubble.size / 2);
            if (distance < requiredDistance) {
              isPositionFree = false;
              break;
            }
          }
        }

        if (isPositionFree) {
          // Agregar la posición a las recientes
          _recentPositions.add(newPosition);
          _lastUsedZone = currentZone;

          // Mantener solo las últimas 15 posiciones
          if (_recentPositions.length > 15) {
            _recentPositions.removeAt(0);
          }

          return newPosition;
        }
      }
    }

    // Fallback: usar distribución forzada por zona considerando tamaño
    int fallbackZone = (_lastUsedZone + 1) % totalZones;
    double zoneWidth = _screenWidth / totalZones;
    double x = fallbackZone * zoneWidth + (zoneWidth - bubbleSize) / 2;
    x = x.clamp(bubbleSize / 2, _screenWidth - bubbleSize / 2);

    _lastUsedZone = fallbackZone;
    return Offset(x, 0);
  }

  // Limpiar posiciones al reiniciar
  void _clearRecentPositions() {
    _recentPositions.clear();
    _lastUsedZone = -1; // Resetear zona
  }

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
    _clearRecentPositions(); // Limpiar posiciones para evitar amontonamiento

    // Configurar tamaño de pantalla
    _screenWidth = MediaQuery.of(context).size.width;

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

      // Intervalo ajustado para mejor distribución temporal
      int interval;
      if (bubblesPopped < 50) {
        // Fase inicial: intervalos más largos para evitar amontonamiento
        interval = (baseInterval - min(bubblesPopped * 10, 600))
            .clamp(1800, baseInterval)
            .toInt();
      } else if (bubblesPopped < 100) {
        // Fase intermedia: intervalos medianos
        interval = (baseInterval - min(bubblesPopped * 15, 1000))
            .clamp(1200, baseInterval)
            .toInt();
      } else {
        // Fase avanzada: intervalos más cortos pero controlados
        interval = (baseInterval - min(bubblesPopped * 20, 1600))
            .clamp(800, baseInterval)
            .toInt();
      }

      interval *= difficultyMultiplier; // Duplicar intervalo si hay power-up

      await Future.delayed(Duration(milliseconds: interval));

      // Verificar nuevamente si no está pausado antes de crear burbujas
      if (!isRunning || isPaused) continue;

      // Configuración mejorada: burbujas controladas y bien espaciadas
      int maxBubblesOnScreen =
          powerUpActive ? 5 : 8; // Reducir cantidad en pantalla

      // Reducir burbujas por ciclo para mejor distribución temporal
      int bubblesThisCycle;
      if (bubblesPopped < 50) {
        // Fase inicial: 1-2 burbujas por ciclo para evitar amontonamiento
        bubblesThisCycle =
            powerUpActive ? 1 : (1 + (bubblesPopped % 30 == 0 ? 1 : 0));
        maxBubblesOnScreen =
            powerUpActive ? 5 : 8; // Menos burbujas en pantalla
      } else if (bubblesPopped < 100) {
        // Fase intermedia: 1-2 burbujas por ciclo
        bubblesThisCycle =
            powerUpActive ? 1 : (1 + (bubblesPopped % 25 == 0 ? 1 : 0));
        maxBubblesOnScreen = powerUpActive ? 5 : 9;
      } else {
        // Fase avanzada: 1-2 burbujas por ciclo más frecuentes
        bubblesThisCycle =
            powerUpActive ? 1 : (1 + (bubblesPopped % 20 == 0 ? 1 : 0));
        maxBubblesOnScreen = powerUpActive ? 6 : 10;
      }

      // Solo crear burbujas si no hay demasiadas en pantalla
      if (bubbles.length < maxBubblesOnScreen) {
        for (int i = 0;
            i < bubblesThisCycle && bubbles.length < maxBubblesOnScreen;
            i++) {
          if (!isRunning || isPaused) break; // Verificar en cada iteración

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
              random.nextDouble() *
                  60; // Burbujas aún más grandes (era 60 + 50)

          // Si es especial, hacer la burbuja dorada y más grande
          if (shouldCreateSpecial) {
            size = 90 +
                random.nextDouble() *
                    40; // Burbujas especiales más grandes (era 80 + 30)
          }

          // Usar sistema anti-amontonamiento mejorado con el tamaño real
          Offset position = _generateUniquePosition(size);

          // Velocidad más lenta al principio, acelera gradualmente
          int speed;
          if (bubblesPopped < 30) {
            // Fase inicial: muy lento para que sea fácil
            speed = (baseSpeed - min(bubblesPopped * 10, 1000))
                .clamp(3000, baseSpeed)
                .toInt();
          } else {
            // Fase normal: acelera más
            speed = (baseSpeed - min(bubblesPopped * 20, 3000))
                .clamp(1500, baseSpeed)
                .toInt();
          }

          // Burbujas más lentas durante power-up
          if (powerUpActive) {
            speed = (speed * 1.8).toInt(); // 80% más lentas
          }

          bubbles.add(Bubble(
            position: position, // Usar posición anti-amontonamiento
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
                volume: 0.15); // Volumen más bajo para menos interferencia
          }

          // Pequeño delay entre burbujas del mismo ciclo para evitar amontonamiento visual
          if (i < bubblesThisCycle - 1) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
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
    // El sonido ahora se reproduce en el BubbleWidget para mejor sincronización
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
