import 'package:flutter/material.dart';
import '../models/game_stats.dart';
import '../widgets/admob_banner.dart';

class StatsScreen extends StatelessWidget {
  final GameStats stats;

  const StatsScreen({super.key, required this.stats});

  // Función para formatear números grandes
  String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  // Función para formatear la fecha del último juego
  String _formatDate(DateTime? date) {
    if (date == null) return 'Nunca';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Calcular estadísticas adicionales
    double avgScore = stats.gameHistory.isNotEmpty
        ? stats.gameHistory.reduce((a, b) => a + b) / stats.gameHistory.length
        : 0;

    int recentGames =
        stats.gameHistory.length > 10 ? 10 : stats.gameHistory.length;

    List<int> recentScores = stats.gameHistory.length > 10
        ? stats.gameHistory.sublist(stats.gameHistory.length - 10)
        : stats.gameHistory;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 135, 206, 235),
      appBar: AppBar(
        title:
            const Text('Estadísticas', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Estadísticas principales
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Estadísticas Generales',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  if (stats.totalGamesPlayed > 0)
                    Text(
                      'Último juego: ${_formatDate(stats.lastPlayed)}',
                      style: const TextStyle(
                          fontSize: 14, color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        title: 'Puntuación Máxima',
                        value: formatNumber(stats.highScore),
                        icon: Icons.emoji_events,
                        color: Colors.amber,
                      ),
                      _StatCard(
                        title: 'Burbujas Totales',
                        value: formatNumber(stats.totalBubblesPopped),
                        icon: Icons.bubble_chart,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        title: 'Juegos Jugados',
                        value: formatNumber(stats.totalGamesPlayed),
                        icon: Icons.games,
                        color: Colors.green,
                      ),
                      _StatCard(
                        title: 'Promedio',
                        value: formatNumber(avgScore.toInt()),
                        icon: Icons.trending_up,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Historial reciente
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Últimos $recentGames Juegos',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: recentScores.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay historial de juegos',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black87),
                              ),
                            )
                          : ListView.builder(
                              itemCount: recentScores.length,
                              itemBuilder: (context, index) {
                                int score = recentScores[
                                    recentScores.length - 1 - index];
                                bool isHighScore = score == stats.highScore;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isHighScore
                                        ? Colors.amber.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isHighScore
                                        ? Border.all(
                                            color: Colors.amber, width: 2)
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Juego ${recentScores.length - index}',
                                        style: const TextStyle(fontSize: 16),
                                        selectionColor: Colors.black87,
                                      ),
                                      Row(
                                        children: [
                                          if (isHighScore)
                                            const Icon(
                                              Icons.emoji_events,
                                              color: Colors.amber,
                                              size: 20,
                                            ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$score puntos',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: isHighScore
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isHighScore
                                                  ? Colors.amber[800]
                                                  : Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdmobBanner(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87, // Hacer más visible
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54, // Hacer más visible que gris
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
