import 'package:cloud_firestore/cloud_firestore.dart';

/// A reply on a [Broadcast]. Replies are visible to everyone in the broadcast
/// audience — there is no private reply path. This public-group model creates
/// an audit trail and discourages side-channel one-to-one contact.
///
/// Deletes are soft: a removed reply stays in Firestore (flagged [deleted]) so
/// administrators retain a complete record, but is hidden from regular members.
class BroadcastReply {
  final String id;
  final String broadcastId;
  final String senderUid;
  final String senderName;
  final String senderRole;
  final String body;
  final bool deleted;
  final String? deletedBy;
  final String? deletedReason;
  final DateTime sentAt;

  const BroadcastReply({
    required this.id,
    required this.broadcastId,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.body,
    this.deleted = false,
    this.deletedBy,
    this.deletedReason,
    required this.sentAt,
  });

  factory BroadcastReply.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BroadcastReply(
      id: doc.id,
      broadcastId: data['broadcastId'] ?? '',
      senderUid: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      body: data['body'] ?? '',
      deleted: data['deleted'] ?? false,
      deletedBy: data['deletedBy'],
      deletedReason: data['deletedReason'],
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toCreatePayload() => {
        'broadcastId': broadcastId,
        'senderUid': senderUid,
        'senderName': senderName,
        'senderRole': senderRole,
        'body': body,
        'deleted': false,
        'sentAt': FieldValue.serverTimestamp(),
      };
}

/// Append-only oversight event for the admin audit log.
class MessageAuditEvent {
  final String id;
  final String type; // broadcast_sent | reply_posted | reply_deleted | user_muted
  final String actorUid;
  final String actorName;
  final String? broadcastId;
  final String? targetUid;
  final Map<String, dynamic> meta;
  final DateTime at;

  const MessageAuditEvent({
    required this.id,
    required this.type,
    required this.actorUid,
    required this.actorName,
    this.broadcastId,
    this.targetUid,
    this.meta = const {},
    required this.at,
  });

  String get label {
    switch (type) {
      case 'broadcast_sent':
        return 'Broadcast sent';
      case 'reply_posted':
        return 'Reply posted';
      case 'reply_deleted':
        return 'Reply removed';
      case 'user_muted':
        return 'User muted';
      case 'user_unmuted':
        return 'User unmuted';
      default:
        return type;
    }
  }

  factory MessageAuditEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageAuditEvent(
      id: doc.id,
      type: data['type'] ?? '',
      actorUid: data['actorUid'] ?? '',
      actorName: data['actorName'] ?? '',
      broadcastId: data['broadcastId'],
      targetUid: data['targetUid'],
      meta: Map<String, dynamic>.from(data['meta'] ?? const {}),
      at: (data['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
