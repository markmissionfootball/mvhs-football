import 'package:cloud_firestore/cloud_firestore.dart';

/// Delivery channels a broadcast can fan out across.
enum BroadcastChannel { push, email, sms }

extension BroadcastChannelX on BroadcastChannel {
  String get label {
    switch (this) {
      case BroadcastChannel.push:
        return 'In-App';
      case BroadcastChannel.email:
        return 'Email';
      case BroadcastChannel.sms:
        return 'Text';
    }
  }
}

/// COMPLIANCE-CRITICAL audience selector.
///
/// A broadcast targets *roles* and *levels* (e.g. "varsity parents"), never an
/// individual student. The recipient set is resolved server-side from this
/// spec, which is what keeps a coach from privately messaging a single minor.
/// See [Broadcast] for the full oversight model.
class BroadcastAudience {
  /// Program / sport this broadcast scopes to. Null = whole department/network.
  final String? programId;

  /// Roles to include: 'player', 'parent', 'coach'. Empty = all roles.
  final List<String> roles;

  /// Team levels to include: 'varsity', 'jv', 'freshman'. Empty = all levels.
  final List<String> levels;

  const BroadcastAudience({
    this.programId,
    this.roles = const [],
    this.levels = const [],
  });

  bool get isWholeNetwork =>
      programId == null && roles.isEmpty && levels.isEmpty;

  /// Human-readable summary, e.g. "Varsity · JV — Players, Parents".
  String get summary {
    final levelPart = levels.isEmpty
        ? 'All levels'
        : levels
            .map((l) => _levelLabels[l] ?? l)
            .join(' · ');
    final rolePart = roles.isEmpty
        ? 'Everyone'
        : roles.map((r) => _roleLabels[r] ?? r).join(', ');
    return '$levelPart — $rolePart';
  }

  static const _levelLabels = {
    'varsity': 'Varsity',
    'jv': 'JV',
    'freshman': 'Freshman',
  };

  static const _roleLabels = {
    'player': 'Players',
    'parent': 'Parents',
    'coach': 'Coaches',
  };

  factory BroadcastAudience.fromMap(Map<String, dynamic> data) {
    return BroadcastAudience(
      programId: data['programId'],
      roles: List<String>.from(data['roles'] ?? const []),
      levels: List<String>.from(data['levels'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'programId': programId,
        'roles': roles,
        'levels': levels,
      };
}

/// Per-channel delivery counters written back by the send Cloud Function.
class BroadcastDelivery {
  final int sent;
  final int failed;

  const BroadcastDelivery({this.sent = 0, this.failed = 0});

  factory BroadcastDelivery.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const BroadcastDelivery();
    return BroadcastDelivery(
      sent: (data['sent'] ?? 0) as int,
      failed: (data['failed'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toMap() => {'sent': sent, 'failed': failed};
}

enum BroadcastStatus { sending, sent, failed }

/// A one-to-many, role-targeted broadcast.
///
/// Unlike `ChatRoom`/`ChatMessage` (which are end-to-end encrypted and private),
/// broadcasts are deliberately stored in plaintext so school administrators can
/// audit them. Transparency — not secrecy — is the student-safety mechanism:
/// coaches select roles instead of individuals, replies are visible to the whole
/// group, and every send/reply/delete is logged for oversight.
class Broadcast {
  final String id;
  final String senderUid;
  final String senderName;
  final String senderRole;
  final String? subject;
  final String body;
  final BroadcastAudience audience;

  /// Snapshot of resolved recipient uids at send time (immutable audit record).
  final List<String> recipientUids;
  final int recipientCount;
  final List<BroadcastChannel> channels;
  final bool allowReplies;
  final String priority; // 'normal' | 'urgent'
  final BroadcastStatus status;
  final Map<String, BroadcastDelivery> delivery;
  final List<String> readBy;
  final DateTime createdAt;
  final DateTime? sentAt;

  const Broadcast({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    this.subject,
    required this.body,
    required this.audience,
    this.recipientUids = const [],
    this.recipientCount = 0,
    this.channels = const [BroadcastChannel.push],
    this.allowReplies = true,
    this.priority = 'normal',
    this.status = BroadcastStatus.sending,
    this.delivery = const {},
    this.readBy = const [],
    required this.createdAt,
    this.sentAt,
  });

  bool get isUrgent => priority == 'urgent';

  String get preview =>
      body.length > 140 ? '${body.substring(0, 140)}…' : body;

  factory Broadcast.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final deliveryRaw =
        (data['delivery'] as Map<String, dynamic>?) ?? const {};
    return Broadcast(
      id: doc.id,
      senderUid: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? '',
      subject: data['subject'],
      body: data['body'] ?? '',
      audience:
          BroadcastAudience.fromMap(data['audience'] as Map<String, dynamic>? ?? const {}),
      recipientUids: List<String>.from(data['recipientUids'] ?? const []),
      recipientCount: (data['recipientCount'] ?? 0) as int,
      channels: (data['channels'] as List<dynamic>?)
              ?.map((c) => BroadcastChannel.values.byName(c as String))
              .toList() ??
          const [BroadcastChannel.push],
      allowReplies: data['allowReplies'] ?? true,
      priority: data['priority'] ?? 'normal',
      status: BroadcastStatus.values.byName(data['status'] ?? 'sent'),
      delivery: deliveryRaw.map(
        (k, v) => MapEntry(
          k,
          BroadcastDelivery.fromMap(v as Map<String, dynamic>?),
        ),
      ),
      readBy: List<String>.from(data['readBy'] ?? const []),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Payload the client writes. Recipient resolution, delivery counters, and
  /// audit logging are owned by the Cloud Function — the client never sets them.
  Map<String, dynamic> toCreatePayload() => {
        'senderUid': senderUid,
        'senderName': senderName,
        'senderRole': senderRole,
        'subject': subject,
        'body': body,
        'audience': audience.toMap(),
        'channels': channels.map((c) => c.name).toList(),
        'allowReplies': allowReplies,
        'priority': priority,
      };
}
