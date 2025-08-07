class GameStats {
  int totalBubblesPopped;
  int totalGamesPlayed;
  int highScore;
  List<int> gameHistory;
  DateTime lastPlayed;

  GameStats({
    this.totalBubblesPopped = 0,
    this.totalGamesPlayed = 0,
    this.highScore = 0,
    List<int>? gameHistory,
    DateTime? lastPlayed,
  }) : gameHistory = gameHistory ?? <int>[],
       lastPlayed = lastPlayed ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'totalBubblesPopped': totalBubblesPopped,
      'totalGamesPlayed': totalGamesPlayed,
      'highScore': highScore,
      'gameHistory': gameHistory,
      'lastPlayed': lastPlayed.toIso8601String(),
    };
  }

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      totalBubblesPopped: json['totalBubblesPopped'] ?? 0,
      totalGamesPlayed: json['totalGamesPlayed'] ?? 0,
      highScore: json['highScore'] ?? 0,
      gameHistory: List<int>.from(json['gameHistory'] ?? []),
      lastPlayed: json['lastPlayed'] != null 
        ? DateTime.parse(json['lastPlayed']) 
        : DateTime.now(),
    );
  }
}
