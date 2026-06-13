import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/broadcast.dart';
import '../models/broadcast_reply.dart';
import '../services/broadcast_service.dart';
import 'auth_provider.dart';

/// Singleton gateway to the broadcast subsystem.
final broadcastServiceProvider =
    Provider<BroadcastService>((ref) => BroadcastService());

/// Broadcasts addressed to the current user (recipient inbox).
final broadcastInboxProvider =
    StreamProvider<List<Broadcast>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(broadcastServiceProvider).streamInbox(uid);
});

/// Broadcasts authored by the current user (sender "Sent" view).
final broadcastSentProvider =
    StreamProvider<List<Broadcast>>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(broadcastServiceProvider).streamSent(uid);
});

/// All broadcasts across the program (admin oversight).
final broadcastAllProvider =
    StreamProvider<List<Broadcast>>((ref) {
  return ref.watch(broadcastServiceProvider).streamAll();
});

/// A single broadcast by id.
final broadcastByIdProvider =
    StreamProvider.family<Broadcast?, String>((ref, id) {
  return ref.watch(broadcastServiceProvider).streamBroadcast(id);
});

/// Public replies on a broadcast. `showDeleted` is driven by the viewer being
/// an admin (decided in the screen, passed via the family arg).
final broadcastRepliesProvider = StreamProvider.family<List<BroadcastReply>,
    ({String broadcastId, bool showDeleted})>((ref, args) {
  return ref.watch(broadcastServiceProvider).streamReplies(
        args.broadcastId,
        showDeleted: args.showDeleted,
      );
});

/// Whether the current user is muted from posting replies.
final currentUserMutedProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(currentUidProvider);
  return ref.watch(broadcastServiceProvider).streamIsMuted(uid);
});

/// Admin audit log (newest first).
final messageAuditProvider =
    StreamProvider<List<MessageAuditEvent>>((ref) {
  return ref.watch(broadcastServiceProvider).streamAuditLog();
});
