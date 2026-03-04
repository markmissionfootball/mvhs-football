import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { player, coach, parent, admin }

class AppUser {
  final String uid;
  final String username;
  final String? email;
  final UserRole role;
  final String? linkedPlayerId;
  final String? linkedCoachId;
  final String displayName;
  final String? avatarUrl;
  final List<String> fcmTokens;
  final String? phoneNumber;
  final bool phoneVerified;
  final List<String> passkeyCredentialIds;
  final bool mustChangePassword;
  final bool mfaComplete;
  final bool onboardingSurveyComplete;
  final String? e2ePublicKey;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.username,
    this.email,
    required this.role,
    this.linkedPlayerId,
    this.linkedCoachId,
    required this.displayName,
    this.avatarUrl,
    this.fcmTokens = const [],
    this.phoneNumber,
    this.phoneVerified = false,
    this.passkeyCredentialIds = const [],
    this.mustChangePassword = true,
    this.mfaComplete = false,
    this.onboardingSurveyComplete = false,
    this.e2ePublicKey,
    required this.createdAt,
  });

  bool get isMasterAdmin => email == 'mark@missionfootball.com';
  bool get isAdminOrAbove => role == UserRole.admin;

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      username: data['username'] ?? '',
      email: data['email'],
      role: UserRole.values.byName(data['role'] ?? 'player'),
      linkedPlayerId: data['linkedPlayerId'],
      linkedCoachId: data['linkedCoachId'],
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      fcmTokens: List<String>.from(data['fcmTokens'] ?? []),
      phoneNumber: data['phoneNumber'],
      phoneVerified: data['phoneVerified'] ?? false,
      passkeyCredentialIds:
          List<String>.from(data['passkeyCredentialIds'] ?? []),
      mustChangePassword: data['mustChangePassword'] ?? true,
      mfaComplete: data['mfaComplete'] ?? false,
      onboardingSurveyComplete: data['onboardingSurveyComplete'] ?? false,
      e2ePublicKey: data['e2ePublicKey'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': username,
      'email': email,
      'role': role.name,
      'linkedPlayerId': linkedPlayerId,
      'linkedCoachId': linkedCoachId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'fcmTokens': fcmTokens,
      'phoneNumber': phoneNumber,
      'phoneVerified': phoneVerified,
      'passkeyCredentialIds': passkeyCredentialIds,
      'mustChangePassword': mustChangePassword,
      'mfaComplete': mfaComplete,
      'onboardingSurveyComplete': onboardingSurveyComplete,
      'e2ePublicKey': e2ePublicKey,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? email,
    UserRole? role,
    String? displayName,
    String? avatarUrl,
    List<String>? fcmTokens,
    String? phoneNumber,
    bool? phoneVerified,
    List<String>? passkeyCredentialIds,
    bool? mustChangePassword,
    bool? mfaComplete,
    bool? onboardingSurveyComplete,
    String? e2ePublicKey,
  }) {
    return AppUser(
      uid: uid,
      username: username,
      email: email ?? this.email,
      role: role ?? this.role,
      linkedPlayerId: linkedPlayerId,
      linkedCoachId: linkedCoachId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      passkeyCredentialIds:
          passkeyCredentialIds ?? this.passkeyCredentialIds,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      mfaComplete: mfaComplete ?? this.mfaComplete,
      onboardingSurveyComplete:
          onboardingSurveyComplete ?? this.onboardingSurveyComplete,
      e2ePublicKey: e2ePublicKey ?? this.e2ePublicKey,
      createdAt: createdAt,
    );
  }
}
