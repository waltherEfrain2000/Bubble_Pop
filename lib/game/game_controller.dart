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
  int baseSpeed = 8000; // Mantener velocidad actual
  int baseInterval =
      800; // Intervalo más corto para más burbujas frecuentes
  bool isRunning = false;
  bool isPaused = false;

  // Sistema anti-amontonamiento mejorado
  final List<Offset> _recentPositions = [];
  final double _minDistance =
      90.0; // Distancia mínima ligeramente reducida para más burbujas
  double _screenWidth = 400.0; // Ancho por defecto
  int _lastUsedZone = -1; // Para alternar zonas

  // Sistema de vidas extra (más restrictivo)
  int nextLifeAt = 30; // Próxima vida a los 30 puntos
  int lifeIncrement = 60; // Cada 60 puntos

  // Sistema de power-ups separado para vida y lentitud
  int nextLifeBubbleAt = 50; // Burbuja de vida cada 50 burbujas reventadas
  int lifeBubbleIncrement = 50; // Cada 50 burbujas
  int nextSlowBubbleAt = 70; // Burbuja de lentitud cada 70 burbujas reventadas
  int slowBubbleIncrement = 70; // Cada 70 burbujas
  bool powerUpActive = false; // Si hay un power-up de lentitud activo
  int powerUpDuration = 5000; // Duración en ms (5 segundos)
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
    const int totalZones = 14; // Más zonas para mejor distribución
    const int maxAttempts = 60; // Más intentos para encontrar espacio

    // Usar un radio de seguridad equilibrado
    double safetyRadius = bubbleSize * 0.8;
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
            // Usar distancia equilibrada para permitir más burbujas
            double requiredDistance = (bubbleSize + bubble.size) / 2 + 15; // 15 píxeles de separación
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

          // Mantener solo las últimas 25 posiciones para más espacio
          if (_recentPositions.length > 25) {
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

    final fallbackPosition = Offset(x, 0);
    
    // Verificar que el fallback no esté muy cerca de burbujas existentes
    for (final bubble in bubbles) {
      final double distance = (fallbackPosition - bubble.position).distance;
      double requiredDistance = (bubbleSize + bubble.size) / 2 + 15;
      if (distance < requiredDistance) {
        // Si está muy cerca, mover horizontalmente
        x += requiredDistance;
        if (x > _screenWidth - bubbleSize / 2) {
          x = bubbleSize / 2;
        }
      }
    }

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
    nextLifeBubbleAt = 50; // Resetear contador de burbuja de vida
    nextSlowBubbleAt = 70; // Resetear contador de burbuja de lentitud
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

      // Intervalo ajustado para más burbujas frecuentes
      int interval;
      if (bubblesPopped < 50) {
        // Fase inicial: intervalos cortos para llenar pantalla
        interval = (baseInterval - min(bubblesPopped * 3, 200))
            .clamp(600, baseInterval)
            .toInt();
      } else if (bubblesPopped < 100) {
        // Fase intermedia: intervalos más cortos
        interval = (baseInterval - min(bubblesPopped * 5, 300))
            .clamp(500, baseInterval)
            .toInt();
      } else {
        // Fase avanzada: intervalos muy cortos para acción intensa
        interval = (baseInterval - min(bubblesPopped * 7, 500))
            .clamp(300, baseInterval)
            .toInt();
      }

      interval *= difficultyMultiplier; // Duplicar intervalo si hay power-up

      await Future.delayed(Duration(milliseconds: interval));

      // Verificar nuevamente si no está pausado antes de crear burbujas
      if (!isRunning || isPaused) continue;

      // Configuración para más burbujas - uso de ambas manos
      int maxBubblesOnScreen =
          powerUpActive ? 10 : 18; // Más burbujas para usar ambas manos

      // Más burbujas por ciclo para llenar la pantalla
      int bubblesThisCycle;
      if (bubblesPopped < 50) {
        // Fase inicial: 2-3 burbujas por ciclo
        bubblesThisCycle =
            powerUpActive ? 2 : (2 + (bubblesPopped % 15 == 0 ? 1 : 0));
        maxBubblesOnScreen =
            powerUpActive ? 10 : 15; // Buena cantidad en pantalla
      } else if (bubblesPopped < 100) {
        // Fase intermedia: 3-4 burbujas por ciclo
        bubblesThisCycle =
            powerUpActive ? 2 : (3 + (bubblesPopped % 12 == 0 ? 1 : 0));
        maxBubblesOnScreen = powerUpActive ? 12 : 18;
      } else {
        // Fase avanzada: 3-5 burbujas por ciclo para máxima acción
        bubblesThisCycle =
            powerUpActive ? 3 : (4 + (bubblesPopped % 10 == 0 ? 1 : 0));
        maxBubblesOnScreen = powerUpActive ? 15 : 22;
      }

      // Solo crear burbujas si no hay demasiadas en pantalla
      if (bubbles.length < maxBubblesOnScreen) {
        // Verificar power-ups antes del ciclo
        bool powerUpCreatedThisCycle = false;
        
        for (int i = 0;
            i < bubblesThisCycle && bubbles.length < maxBubblesOnScreen;
            i++) {
          if (!isRunning || isPaused) break; // Verificar en cada iteración

          // Determinar si crear burbuja especial según el tipo (solo una por ciclo)
          bool shouldCreateLifeBubble = bubblesPopped >= nextLifeBubbleAt && !powerUpCreatedThisCycle;
          bool shouldCreateSlowBubble = bubblesPopped >= nextSlowBubbleAt && !powerUpActive && !powerUpCreatedThisCycle;
          
          // Priorizar burbuja de lentitud si ambas están disponibles
          bool shouldCreateSpecial = false;
          String specialType = 'normal';
          
          if (shouldCreateSlowBubble) {
            shouldCreateSpecial = true;
            specialType = 'slow';
            nextSlowBubbleAt = bubblesPopped + slowBubbleIncrement; // Establecer próximo objetivo
            powerUpCreatedThisCycle = true;
          } else if (shouldCreateLifeBubble) {
            shouldCreateSpecial = true;
            specialType = 'life';
            nextLifeBubbleAt = bubblesPopped + lifeBubbleIncrement; // Establecer próximo objetivo
            powerUpCreatedThisCycle = true;
          }

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
            specialType: specialType,
          ));

          if (!isPaused) {
            await spawnPlayer.play(AssetSource('sounds/bubble_spawn.mp3'),
                volume: 0.15); // Volumen más bajo para menos interferencia
          }

          // Delay optimizado para distribución rápida pero controlada
          if (i < bubblesThisCycle - 1) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        }
      }
      onUpdate();
    }
  }

  void popBubble(Bubble bubble) async {
    bubbles.removeWhere((b) => b.key == bubble.key);

    // Si es una burbuja especial de vida, dar vida extra
    if (bubble.isSpecial && bubble.specialType == 'life' && currentLives < 5) {
      currentLives += 1;
      score += 5; // Bonus de puntos por burbuja especial
      await bonusPlayer.play(AssetSource('sounds/bubble_spawn.mp3'));
      onUpdate(); // Actualizar UI inmediatamente
    } 
    // Si es una burbuja especial de lentitud, activar power-up
    else if (bubble.isSpecial && bubble.specialType == 'slow' && !powerUpActive) {
      score += 5; // Bonus de puntos por burbuja especial
      activatePowerUp(); // Activar power-up de lentitud
    } 
    else {
      score += 1;
    }

    bubblesPopped += 1;

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
    
    // Solo perder vida si NO es una burbuja especial (power-up)
    if (!bubble.isSpecial) {
      currentLives -= 1; // Perder una vida solo por burbujas normales
    }
    
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
