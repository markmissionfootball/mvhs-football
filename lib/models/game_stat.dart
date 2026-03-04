import 'package:cloud_firestore/cloud_firestore.dart';

class DefensiveStat {
  final String playerId;
  final int playerNumber;
  final int soloTackles;
  final int assistedTackles;
  final int tfls;
  final int sacks;
  final int passDeflections;
  final int interceptions;
  final int forcedFumbles;
  final int fumbleRecoveries;
  final bool isStarter;

  const DefensiveStat({
    required this.playerId,
    required this.playerNumber,
    this.soloTackles = 0,
    this.assistedTackles = 0,
    this.tfls = 0,
    this.sacks = 0,
    this.passDeflections = 0,
    this.interceptions = 0,
    this.forcedFumbles = 0,
    this.fumbleRecoveries = 0,
    this.isStarter = false,
  });

  int get totalTackles => soloTackles + assistedTackles;

  factory DefensiveStat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final tackles = data['tackles'] as Map<String, dynamic>? ?? {};
    return DefensiveStat(
      playerId: data['playerId'] ?? doc.id,
      playerNumber: data['playerNumber'] ?? 0,
      soloTackles: tackles['solo'] ?? 0,
      assistedTackles: tackles['assisted'] ?? 0,
      tfls: data['tfls'] ?? 0,
      sacks: data['sacks'] ?? 0,
      passDeflections: data['passDeflections'] ?? 0,
      interceptions: data['interceptions'] ?? 0,
      forcedFumbles: data['forcedFumbles'] ?? 0,
      fumbleRecoveries: data['fumbleRecoveries'] ?? 0,
      isStarter: data['isStarter'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'playerId': playerId,
      'playerNumber': playerNumber,
      'tackles': {'solo': soloTackles, 'assisted': assistedTackles},
      'tfls': tfls,
      'sacks': sacks,
      'passDeflections': passDeflections,
      'interceptions': interceptions,
      'forcedFumbles': forcedFumbles,
      'fumbleRecoveries': fumbleRecoveries,
      'isStarter': isStarter,
    };
  }
}

class GameAwards {
  final String? playerOfGame;
  final String? offensivePOG;
  final String? defensivePOG;
  final String? specialTeamsPOG;

  const GameAwards({
    this.playerOfGame,
    this.offensivePOG,
    this.defensivePOG,
    this.specialTeamsPOG,
  });

  factory GameAwards.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameAwards(
      playerOfGame: data['playerOfGame'],
      offensivePOG: data['offensivePOG'],
      defensivePOG: data['defensivePOG'],
      specialTeamsPOG: data['specialTeamsPOG'],
    );
  }
}
