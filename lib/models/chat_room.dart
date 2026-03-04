import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatRoomType { dm, group }

class EncryptedRoomKey {
  final String recipientUid;
  final String encryptedKey;
  final String ephemeralPublicKey;
  final String nonce;

  const EncryptedRoomKey({
    required this.recipientUid,
    required this.encryptedKey,
    required this.ephemeralPublicKey,
    required this.nonce,
  });

  factory EncryptedRoomKey.fromMap(Map<String, dynamic> data) {
    return EncryptedRoomKey(
      recipientUid: data['recipientUid'] ?? '',
      encryptedKey: data['encryptedKey'] ?? '',
      ephemeralPublicKey: data['ephemeralPublicKey'] ?? '',
      nonce: data['nonce'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'recipientUid': recipientUid,
        'encryptedKey': encryptedKey,
        'ephemeralPublicKey': ephemeralPublicKey,
        'nonce': nonce,
      };
}

class ChatRoom {
  final String id;
  final ChatRoomType type;
  final String? name;
  final List<String> participantUids;
  final Map<String, String> participantNames;
  final List<EncryptedRoomKey> encryptedKeys;
  final DateTime? lastMessageAt;
  final String createdBy;
  final DateTime createdAt;

  const ChatRoom({
    required this.id,
    required this.type,
    this.name,
    required this.participantUids,
    this.participantNames = const {},
    this.encryptedKeys = const [],
    this.lastMessageAt,
    required this.createdBy,
    required this.createdAt,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      type: ChatRoomType.values.byName(data['type'] ?? 'dm'),
      name: data['name'],
      participantUids: List<String>.from(data['participantUids'] ?? []),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? {}),
      encryptedKeys: (data['encryptedKeys'] as List<dynamic>?)
              ?.map(
                  (e) => EncryptedRoomKey.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'name': name,
      'participantUids': participantUids,
      'participantNames': participantNames,
      'encryptedKeys': encryptedKeys.map((k) => k.toMap()).toList(),
      'lastMessageAt':
          lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Display name for this room from the perspective of [currentUid].
  String displayName(String currentUid) {
    if (type == ChatRoomType.group) return name ?? 'Group Chat';
    // DM: show the other participant's name
    final otherUid = participantUids.firstWhere(
      (uid) => uid != currentUid,
      orElse: () => currentUid,
    );
    return participantNames[otherUid] ?? 'Player';
  }
}
