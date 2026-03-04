import 'package:cloud_firestore/cloud_firestore.dart';

class CombineResult {
  final String playerId;
  final double? fortyYd;
  final double? proShuttle;
  final double? threeCone;
  final double? broadJump;
  final double? vertical;
  final double? reach;
  final double? weight;
  final String? height;

  const CombineResult({
    required this.playerId,
    this.fortyYd,
    this.proShuttle,
    this.threeCone,
    this.broadJump,
    this.vertical,
    this.reach,
    this.weight,
    this.height,
  });

  factory CombineResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CombineResult(
      playerId: data['playerId'] ?? doc.id,
      fortyYd: (data['fortyYd'] as num?)?.toDouble(),
      proShuttle: (data['proShuttle'] as num?)?.toDouble(),
      threeCone: (data['threeCone'] as num?)?.toDouble(),
      broadJump: (data['broadJump'] as num?)?.toDouble(),
      vertical: (data['vertical'] as num?)?.toDouble(),
      reach: (data['reach'] as num?)?.toDouble(),
      weight: (data['weight'] as num?)?.toDouble(),
      height: data['height'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'playerId': playerId,
      'fortyYd': fortyYd,
      'proShuttle': proShuttle,
      'threeCone': threeCone,
      'broadJump': broadJump,
      'vertical': vertical,
      'reach': reach,
      'weight': weight,
      'height': height,
    };
  }
}
