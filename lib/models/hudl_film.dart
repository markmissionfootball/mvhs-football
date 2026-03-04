import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single game film imported from Hudl.
class HudlFilm {
  final String id;
  final String gameId;           // Links to games collection
  final String opponent;
  final DateTime gameDate;
  final String season;
  final String level;            // varsity, jv, freshman
  final String? hudlVideoUrl;    // Deep link to Hudl video
  final String? hudlVideoId;     // Hudl's internal video ID
  final int totalPlays;
  final String importedBy;       // UID of coach who imported
  final DateTime importedAt;
  final FilmStatus status;       // pending, processing, ready, error
  final FilmSummary? summary;    // AI-generated game summary

  const HudlFilm({
    required this.id,
    required this.gameId,
    required this.opponent,
    required this.gameDate,
    required this.season,
    required this.level,
    this.hudlVideoUrl,
    this.hudlVideoId,
    required this.totalPlays,
    required this.importedBy,
    required this.importedAt,
    this.status = FilmStatus.pending,
    this.summary,
  });

  factory HudlFilm.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HudlFilm(
      id: doc.id,
      gameId: data['gameId'] ?? '',
      opponent: data['opponent'] ?? '',
      gameDate: (data['gameDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      season: data['season'] ?? '',
      level: data['level'] ?? 'varsity',
      hudlVideoUrl: data['hudlVideoUrl'],
      hudlVideoId: data['hudlVideoId'],
      totalPlays: data['totalPlays'] ?? 0,
      importedBy: data['importedBy'] ?? '',
      importedAt: (data['importedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: FilmStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => FilmStatus.pending,
      ),
      summary: data['summary'] != null
          ? FilmSummary.fromMap(data['summary'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'gameId': gameId,
    'opponent': opponent,
    'gameDate': Timestamp.fromDate(gameDate),
    'season': season,
    'level': level,
    'hudlVideoUrl': hudlVideoUrl,
    'hudlVideoId': hudlVideoId,
    'totalPlays': totalPlays,
    'importedBy': importedBy,
    'importedAt': Timestamp.fromDate(importedAt),
    'status': status.name,
    'summary': summary?.toMap(),
  };
}

enum FilmStatus { pending, processing, ready, error }

/// AI-generated summary of a game film.
class FilmSummary {
  final String overview;
  final List<String> keyTakeaways;
  final Map<String, double> teamGrades;  // e.g., {'offense': 82.5, 'defense': 78.0}

  const FilmSummary({
    required this.overview,
    this.keyTakeaways = const [],
    this.teamGrades = const {},
  });

  factory FilmSummary.fromMap(Map<String, dynamic> data) => FilmSummary(
    overview: data['overview'] ?? '',
    keyTakeaways: List<String>.from(data['keyTakeaways'] ?? []),
    teamGrades: Map<String, double>.from(data['teamGrades'] ?? {}),
  );

  Map<String, dynamic> toMap() => {
    'overview': overview,
    'keyTakeaways': keyTakeaways,
    'teamGrades': teamGrades,
  };
}

/// A single tagged play from Hudl breakdown data.
class HudlPlay {
  final String id;
  final String filmId;
  final int playNumber;
  final int quarter;
  final String downAndDistance;   // e.g., "2nd & 7"
  final int yardLine;
  final String formation;        // e.g., "Shotgun Trips Right"
  final String playType;         // run, pass, special_teams
  final String playCall;         // e.g., "Inside Zone Left"
  final String result;           // e.g., "Complete - 12 yards"
  final int yardsGained;
  final bool isTurnover;
  final bool isTouchdown;
  final bool isPenalty;
  final String? penaltyDetail;
  final String? videoTimestamp;   // Hudl timestamp for this play
  final List<String> taggedPlayerIds;  // Player IDs involved
  final String? coachNote;       // Coach annotation

  const HudlPlay({
    required this.id,
    required this.filmId,
    required this.playNumber,
    required this.quarter,
    required this.downAndDistance,
    required this.yardLine,
    required this.formation,
    required this.playType,
    required this.playCall,
    required this.result,
    required this.yardsGained,
    this.isTurnover = false,
    this.isTouchdown = false,
    this.isPenalty = false,
    this.penaltyDetail,
    this.videoTimestamp,
    this.taggedPlayerIds = const [],
    this.coachNote,
  });

  factory HudlPlay.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HudlPlay(
      id: doc.id,
      filmId: data['filmId'] ?? '',
      playNumber: data['playNumber'] ?? 0,
      quarter: data['quarter'] ?? 1,
      downAndDistance: data['downAndDistance'] ?? '',
      yardLine: data['yardLine'] ?? 0,
      formation: data['formation'] ?? '',
      playType: data['playType'] ?? '',
      playCall: data['playCall'] ?? '',
      result: data['result'] ?? '',
      yardsGained: data['yardsGained'] ?? 0,
      isTurnover: data['isTurnover'] ?? false,
      isTouchdown: data['isTouchdown'] ?? false,
      isPenalty: data['isPenalty'] ?? false,
      penaltyDetail: data['penaltyDetail'],
      videoTimestamp: data['videoTimestamp'],
      taggedPlayerIds: List<String>.from(data['taggedPlayerIds'] ?? []),
      coachNote: data['coachNote'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'filmId': filmId,
    'playNumber': playNumber,
    'quarter': quarter,
    'downAndDistance': downAndDistance,
    'yardLine': yardLine,
    'formation': formation,
    'playType': playType,
    'playCall': playCall,
    'result': result,
    'yardsGained': yardsGained,
    'isTurnover': isTurnover,
    'isTouchdown': isTouchdown,
    'isPenalty': isPenalty,
    'penaltyDetail': penaltyDetail,
    'videoTimestamp': videoTimestamp,
    'taggedPlayerIds': taggedPlayerIds,
    'coachNote': coachNote,
  };
}

/// Per-player stats from a single game film.
class HudlPlayerStats {
  final String id;
  final String filmId;
  final String playerId;
  final String playerName;
  final String position;
  final Map<String, dynamic> stats;  // Flexible stat map (varies by position)
  final double? overallGrade;        // AI-generated 0-100 grade
  final String? gradeLabel;          // e.g., "Above Average", "Elite"
  final List<String> strengths;      // AI-identified strengths
  final List<String> areasToImprove; // AI-identified growth areas
  final List<int> highlightPlays;    // Play numbers for highlight reel
  final String? aiAnalysis;          // Full AI coaching analysis

  const HudlPlayerStats({
    required this.id,
    required this.filmId,
    required this.playerId,
    required this.playerName,
    required this.position,
    this.stats = const {},
    this.overallGrade,
    this.gradeLabel,
    this.strengths = const [],
    this.areasToImprove = const [],
    this.highlightPlays = const [],
    this.aiAnalysis,
  });

  factory HudlPlayerStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HudlPlayerStats(
      id: doc.id,
      filmId: data['filmId'] ?? '',
      playerId: data['playerId'] ?? '',
      playerName: data['playerName'] ?? '',
      position: data['position'] ?? '',
      stats: Map<String, dynamic>.from(data['stats'] ?? {}),
      overallGrade: (data['overallGrade'] as num?)?.toDouble(),
      gradeLabel: data['gradeLabel'],
      strengths: List<String>.from(data['strengths'] ?? []),
      areasToImprove: List<String>.from(data['areasToImprove'] ?? []),
      highlightPlays: List<int>.from(data['highlightPlays'] ?? []),
      aiAnalysis: data['aiAnalysis'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'filmId': filmId,
    'playerId': playerId,
    'playerName': playerName,
    'position': position,
    'stats': stats,
    'overallGrade': overallGrade,
    'gradeLabel': gradeLabel,
    'strengths': strengths,
    'areasToImprove': areasToImprove,
    'highlightPlays': highlightPlays,
    'aiAnalysis': aiAnalysis,
  };
}
