import 'package:cloud_firestore/cloud_firestore.dart';

class DepthChartPlayer {
  final String playerId;
  final String name;
  final int? depth;

  const DepthChartPlayer({
    required this.playerId,
    required this.name,
    this.depth,
  });

  factory DepthChartPlayer.fromMap(Map<String, dynamic> data) {
    return DepthChartPlayer(
      playerId: data['playerId'] ?? '',
      name: data['name'] ?? '',
      depth: data['depth'],
    );
  }

  Map<String, dynamic> toMap() => {
        'playerId': playerId,
        'name': name,
        'depth': depth,
      };
}

class DepthChartPosition {
  final String position;
  final List<DepthChartPlayer> starters;
  final List<DepthChartPlayer> backups;

  const DepthChartPosition({
    required this.position,
    this.starters = const [],
    this.backups = const [],
  });

  factory DepthChartPosition.fromMap(Map<String, dynamic> data) {
    return DepthChartPosition(
      position: data['position'] ?? '',
      starters: (data['starters'] as List<dynamic>?)
              ?.map(
                  (p) => DepthChartPlayer.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      backups: (data['backups'] as List<dynamic>?)
              ?.map(
                  (p) => DepthChartPlayer.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'position': position,
        'starters': starters.map((p) => p.toMap()).toList(),
        'backups': backups.map((p) => p.toMap()).toList(),
      };
}

class DepthChart {
  final String id;
  final String season;
  final String type; // "offense", "defense", "special_teams"
  final List<DepthChartPosition> positions;
  final DateTime updatedAt;

  const DepthChart({
    required this.id,
    required this.season,
    required this.type,
    required this.positions,
    required this.updatedAt,
  });

  factory DepthChart.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DepthChart(
      id: doc.id,
      season: data['season'] ?? '',
      type: data['type'] ?? '',
      positions: (data['positions'] as List<dynamic>?)
              ?.map((p) =>
                  DepthChartPosition.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'season': season,
      'type': type,
      'positions': positions.map((p) => p.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
