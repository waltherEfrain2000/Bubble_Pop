import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bubble.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameController {
  List<Bubble> bubbles = [];
  final Random random = Random();
  final AudioPlayer popPlayer = AudioPlayer();
  final AudioPlayer musicPlayer = AudioPlayer();
  final AudioPlayer spawnPlayer = AudioPlayer();
  int score = 0;
  int highScore = 0;
  int bubblesPopped = 0;
  int bubblesMissed = 0;
  int baseSpeed = 2000;
  int baseInterval = 800;
  bool isRunning = false;
  bool isPaused = false;
  final VoidCallback onUpdate;
  final Function(int score, int highScore) onGameOver;

  GameController({
    required this.onUpdate,
    required this.onGameOver,
  });

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('highScore') ?? 0;
    onUpdate();
  }

  Future<void> updateHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      highScore = score;
      await prefs.setInt('highScore', highScore);
      onUpdate();
    }
  }

  void start(BuildContext context) async {
    isRunning = true;
    isPaused = false;
    await loadHighScore();
    score = 0;
    bubblesPopped = 0;
    bubblesMissed = 0;
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
    while (isRunning && !isPaused) {
      int interval = (baseInterval - min(bubblesPopped * 2, 600)).clamp(180, baseInterval).toInt();
      await Future.delayed(Duration(milliseconds: interval));
      if (!isRunning || isPaused) break;

      int bubblesThisCycle = 1 + (bubblesPopped ~/ 10);

      for (int i = 0; i < bubblesThisCycle; i++) {
        double posX = random.nextDouble() * (MediaQuery.of(context).size.width - 50);
        int speed = (baseSpeed - min(bubblesPopped * 10, 1200)).clamp(600, baseSpeed).toInt();
        List<String> bubbleImages = [
          'assets/images/bubble1.png',
          'assets/images/bubble2.png',
          'assets/images/bubble3.png'
        ];
        String img = bubbleImages[random.nextInt(bubbleImages.length)];
        double size = 40 + random.nextDouble() * 40;
        bubbles.add(Bubble(
          position: Offset(posX, 0),
          size: size,
          speed: speed,
          key: UniqueKey(),
          image: img,
        ));
        await spawnPlayer.play(AssetSource('sounds/bubble_spawn.mp3'), volume: 0.2);
      }
      onUpdate();
    }
  }

  void popBubble(Bubble bubble) async {
    bubbles.removeWhere((b) => b.key == bubble.key);
    score += 1;
    bubblesPopped += 1;
    onUpdate();
    await updateHighScore();
    await popPlayer.play(AssetSource('sounds/pop.mp3'));
  }

  void removeBubbleWithoutSound(Bubble bubble) {
    bubbles.removeWhere((b) => b.key == bubble.key);
    bubblesMissed += 1;
    onUpdate();
    if (bubblesMissed >= 3) {
      isRunning = false;
      isPaused = false;
      musicPlayer.stop();
      onGameOver(score, highScore);
    }
  }

  void pauseGame() {
    isPaused = true;
    musicPlayer.pause();
  }

  void resumeGame(BuildContext context) {
    if (isPaused) {
      isPaused = false;
      musicPlayer.resume();
      _spawnLoop(context);
    }
  }

  void dispose() {
    isRunning = false;
    isPaused = false;
    popPlayer.dispose();
    musicPlayer.dispose();
    spawnPlayer.dispose();
  }
}