import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/admob_banner.dart';
import '../models/game_stats.dart';
import 'stats_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  GameStats gameStats = GameStats();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    String? statsJson = prefs.getString('gameStats');
    if (statsJson != null) {
      gameStats = GameStats.fromJson(json.decode(statsJson));
    }
    setState(() {
      isLoading = false;
    });
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bubble Pop',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              
              // Mostrar estadísticas rápidas
              if (!isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${gameStats.highScore}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const Text('Récord', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '${gameStats.totalBubblesPopped}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text('Burbujas', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '${gameStats.totalGamesPlayed}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text('Juegos', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/game'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Jugar', style: TextStyle(fontSize: 28)),
              ),
              
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatsScreen(stats: gameStats),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade300,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text('Estadísticas', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AdmobBanner(),
    );
  }
}
