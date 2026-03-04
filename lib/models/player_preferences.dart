import 'package:cloud_firestore/cloud_firestore.dart';

enum AgentTone { coach, buddy, allBusiness }

enum TopPriority { recruiting, strength, gamePrep, academics }

enum RecruitingInterest { high, some, notYet }

class PlayerPreferences {
  final String playerId;
  final List<String> goals;
  final RecruitingInterest recruitingInterest;
  final String? preferredCollege;
  final AgentTone agentTone;
  final TopPriority topPriority;
  final DateTime updatedAt;

  const PlayerPreferences({
    required this.playerId,
    this.goals = const [],
    this.recruitingInterest = RecruitingInterest.notYet,
    this.preferredCollege,
    this.agentTone = AgentTone.coach,
    this.topPriority = TopPriority.strength,
    required this.updatedAt,
  });

  factory PlayerPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlayerPreferences(
      playerId: data['playerId'] ?? doc.id,
      goals: List<String>.from(data['goals'] ?? []),
      recruitingInterest: RecruitingInterest.values.byName(
        (data['recruitingInterest'] ?? 'notYet')
            .toString()
            .replaceAll('_', ''),
      ),
      preferredCollege: data['preferredCollege'],
      agentTone: AgentTone.values.byName(
        (data['agentTone'] ?? 'coach').toString().replaceAll('_', ''),
      ),
      topPriority: TopPriority.values.byName(
        (data['topPriority'] ?? 'strength').toString().replaceAll('_', ''),
      ),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'playerId': playerId,
      'goals': goals,
      'recruitingInterest': recruitingInterest.name,
      'preferredCollege': preferredCollege,
      'agentTone': agentTone.name,
      'topPriority': topPriority.name,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
