import 'package:cloud_firestore/cloud_firestore.dart';

class GameResult {
  final int mvScore;
  final int oppScore;
  final bool win;

  const GameResult({
    required this.mvScore,
    required this.oppScore,
    required this.win,
  });

  factory GameResult.fromMap(Map<String, dynamic> data) {
    return GameResult(
      mvScore: data['mvScore'] ?? 0,
      oppScore: data['oppScore'] ?? 0,
      win: data['win'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'mvScore': mvScore,
        'oppScore': oppScore,
        'win': win,
      };
}

class Game {
  final String id;
  final String season;
  final int week;
  final DateTime date;
  final String opponent;
  final String location; // "home" or "away"
  final String time;
  final String level; // "varsity", "jv", "freshman"
  final GameResult? result;
  final String? notes;

  const Game({
    required this.id,
    required this.season,
    required this.week,
    required this.date,
    required this.opponent,
    required this.location,
    required this.time,
    required this.level,
    this.result,
    this.notes,
  });

  bool get isHome => location == 'home';
  bool get isPlayed => result != null;

  factory Game.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Game(
      id: doc.id,
      season: data['season'] ?? '',
      week: data['week'] ?? 0,
      date: (data['date'] as Timestamp).toDate(),
      opponent: data['opponent'] ?? '',
      location: data['location'] ?? 'home',
      time: data['time'] ?? '',
      level: data['level'] ?? 'varsity',
      result: data['result'] != null
          ? GameResult.fromMap(data['result'] as Map<String, dynamic>)
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'season': season,
      'week': week,
      'date': Timestamp.fromDate(date),
      'opponent': opponent,
      'location': location,
      'time': time,
      'level': level,
      'result': result?.toMap(),
      'notes': notes,
    };
  }
}
