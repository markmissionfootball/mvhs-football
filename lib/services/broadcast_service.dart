import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/broadcast.dart';
import '../models/broadcast_reply.dart';

/// Result of a send attempt, surfaced to the compose screen.
class BroadcastSendResult {
  final bool ok;
  final String? broadcastId;
  final int recipientCount;
  final String? error;

  const BroadcastSendResult({
    required this.ok,
    this.broadcastId,
    this.recipientCount = 0,
    this.error,
  });
}

/// Estimated audience size for a target spec, used for the live recipient
/// counter on the compose screen.
class AudiencePreview {
  final int total;
  final Map<String, int> byRole;

  const AudiencePreview({this.total = 0, this.byRole = const {}});
}

/// Client gateway for the compliant broadcast subsystem.
///
/// Sends go through a Cloud Function (`sendBroadcast`) rather than a direct
/// Firestore write, so the server stays the single authority on audience
/// resolution, multi-channel fan-out, and audit logging. Reads stream straight
/// from Firestore using the security-rule-enforced collections.
class BroadcastService {
  BroadcastService({FirebaseFirestore? db, FirebaseFunctions? functions})
      : _db = db ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _broadcasts =>
      _db.collection('broadcasts');

  // ── Send ──────────────────────────────────────────────────────────

  /// Sends a broadcast. The Cloud Function validates that the caller is a
  /// coach/admin, resolves the audience from roles+levels (never an individual),
  /// fans out across the selected channels, and writes the audit record.
  Future<BroadcastSendResult> send(Broadcast draft) async {
    try {
      final callable = _functions.httpsCallable('sendBroadcast');
      final result = await callable.call(draft.toCreatePayload());
      final data = Map<String, dynamic>.from(result.data as Map);
      return BroadcastSendResult(
        ok: data['ok'] == true,
        broadcastId: data['broadcastId'] as String?,
        recipientCount: (data['recipientCount'] ?? 0) as int,
        error: data['error'] as String?,
      );
    } on FirebaseFunctionsException catch (e) {
      return BroadcastSendResult(ok: false, error: e.message ?? e.code);
    } catch (e) {
      return BroadcastSendResult(ok: false, error: e.toString());
    }
  }

  /// Live recipient-count estimate for the compose screen.
  Future<AudiencePreview> previewAudience(BroadcastAudience audience) async {
    try {
      final callable = _functions.httpsCallable('previewBroadcastAudience');
      final result = await callable.call(audience.toMap());
      final data = Map<String, dynamic>.from(result.data as Map);
      return AudiencePreview(
        total: (data['total'] ?? 0) as int,
        byRole: Map<String, int>.from(data['byRole'] ?? const {}),
      );
    } catch (_) {
      return const AudiencePreview();
    }
  }

  // ── Inbox / reads ─────────────────────────────────────────────────

  /// Broadcasts addressed to [uid] (recipient inbox), newest first.
  Stream<List<Broadcast>> streamInbox(String uid, {int limit = 50}) {
    return _broadcasts
        .where('recipientUids', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Broadcast.fromFirestore).toList());
  }

  /// Broadcasts authored by [uid] (sender's "Sent" view), newest first.
  Stream<List<Broadcast>> streamSent(String uid, {int limit = 50}) {
    return _broadcasts
        .where('senderUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Broadcast.fromFirestore).toList());
  }

  /// Every broadcast across the program (admin oversight), newest first.
  Stream<List<Broadcast>> streamAll({int limit = 100}) {
    return _broadcasts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(Broadcast.fromFirestore).toList());
  }

  Future<Broadcast?> getBroadcast(String id) async {
    final doc = await _broadcasts.doc(id).get();
    return doc.exists ? Broadcast.fromFirestore(doc) : null;
  }

  Stream<Broadcast?> streamBroadcast(String id) {
    return _broadcasts
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? Broadcast.fromFirestore(d) : null);
  }

  /// Marks a broadcast read by [uid] (idempotent).
  Future<void> markRead(String broadcastId, String uid) async {
    try {
      await _broadcasts.doc(broadcastId).update({
        'readBy': FieldValue.arrayUnion([uid]),
      });
    } catch (_) {
      // Non-fatal: a failed read-receipt should never block the UI.
    }
  }

  // ── Replies (public group) ────────────────────────────────────────

  /// Replies on a broadcast, oldest first. Soft-deleted replies are included so
  /// admins can still see them; the UI is responsible for honoring [showDeleted].
  Stream<List<BroadcastReply>> streamReplies(
    String broadcastId, {
    bool showDeleted = false,
  }) {
    return _broadcasts
        .doc(broadcastId)
        .collection('replies')
        .orderBy('sentAt')
        .snapshots()
        .map((s) => s.docs
            .map(BroadcastReply.fromFirestore)
            .where((r) => showDeleted || !r.deleted)
            .toList());
  }

  /// Posts a public reply visible to the whole audience.
  Future<void> postReply(BroadcastReply reply) async {
    await _broadcasts
        .doc(reply.broadcastId)
        .collection('replies')
        .add(reply.toCreatePayload());
  }

  // ── Admin oversight actions ───────────────────────────────────────

  /// Soft-deletes a reply (admins retain visibility; members do not).
  Future<void> deleteReply({
    required String broadcastId,
    required String replyId,
    required String adminUid,
    String? reason,
  }) async {
    await _broadcasts
        .doc(broadcastId)
        .collection('replies')
        .doc(replyId)
        .update({
      'deleted': true,
      'deletedBy': adminUid,
      'deletedReason': reason,
    });
  }

  /// Mutes a user from posting replies. Backed by the `mutes/{uid}` doc, which
  /// the security rules consult before allowing a reply write.
  Future<void> muteUser({
    required String uid,
    required String adminUid,
    String? reason,
  }) async {
    await _db.collection('mutes').doc(uid).set({
      'mutedBy': adminUid,
      'reason': reason,
      'mutedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unmuteUser(String uid) async {
    await _db.collection('mutes').doc(uid).delete();
  }

  Stream<bool> streamIsMuted(String uid) {
    return _db
        .collection('mutes')
        .doc(uid)
        .snapshots()
        .map((d) => d.exists);
  }

  /// Append-only oversight log, newest first (admin only).
  Stream<List<MessageAuditEvent>> streamAuditLog({int limit = 200}) {
    return _db
        .collection('messageAudit')
        .orderBy('at', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(MessageAuditEvent.fromFirestore).toList());
  }
}
