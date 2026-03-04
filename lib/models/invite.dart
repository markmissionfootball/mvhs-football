import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';

class Invite {
  final String id;
  final String email;
  final String inviteCode;
  final UserRole role;
  final String displayName;
  final String? linkedPlayerId;
  final String? linkedCoachId;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool claimed;
  final DateTime? claimedAt;
  final String? claimedByUid;

  const Invite({
    required this.id,
    required this.email,
    required this.inviteCode,
    required this.role,
    required this.displayName,
    this.linkedPlayerId,
    this.linkedCoachId,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.claimed = false,
    this.claimedAt,
    this.claimedByUid,
  });

  factory Invite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invite(
      id: doc.id,
      email: data['email'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      role: UserRole.values.byName(data['role'] ?? 'player'),
      displayName: data['displayName'] ?? '',
      linkedPlayerId: data['linkedPlayerId'],
      linkedCoachId: data['linkedCoachId'],
      createdBy: data['createdBy'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      claimed: data['claimed'] ?? false,
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate(),
      claimedByUid: data['claimedByUid'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'inviteCode': inviteCode,
      'role': role.name,
      'displayName': displayName,
      'linkedPlayerId': linkedPlayerId,
      'linkedCoachId': linkedCoachId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'claimed': claimed,
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'claimedByUid': claimedByUid,
    };
  }

  Invite copyWith({
    String? email,
    String? inviteCode,
    UserRole? role,
    String? displayName,
    String? linkedPlayerId,
    String? linkedCoachId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? claimed,
    DateTime? claimedAt,
    String? claimedByUid,
  }) {
    return Invite(
      id: id,
      email: email ?? this.email,
      inviteCode: inviteCode ?? this.inviteCode,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      linkedPlayerId: linkedPlayerId ?? this.linkedPlayerId,
      linkedCoachId: linkedCoachId ?? this.linkedCoachId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      claimed: claimed ?? this.claimed,
      claimedAt: claimedAt ?? this.claimedAt,
      claimedByUid: claimedByUid ?? this.claimedByUid,
    );
  }
}
