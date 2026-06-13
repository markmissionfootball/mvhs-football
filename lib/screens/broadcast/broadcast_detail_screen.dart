import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/broadcast.dart';
import '../../models/broadcast_reply.dart';
import '../../providers/auth_provider.dart';
import '../../providers/broadcast_provider.dart';
import '../../theme/diablo_colors.dart';

/// Read a broadcast and its public group replies. Coaches/admins can remove
/// replies; admins additionally see soft-deleted replies (oversight).
class BroadcastDetailScreen extends ConsumerStatefulWidget {
  const BroadcastDetailScreen({super.key, required this.broadcastId});

  final String broadcastId;

  @override
  ConsumerState<BroadcastDetailScreen> createState() =>
      _BroadcastDetailScreenState();
}

class _BroadcastDetailScreenState
    extends ConsumerState<BroadcastDetailScreen> {
  final _replyController = TextEditingController();
  bool _posting = false;
  bool _markedRead = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _maybeMarkRead(Broadcast b) {
    if (_markedRead) return;
    final uid = ref.read(currentUidProvider);
    if (!b.readBy.contains(uid)) {
      ref.read(broadcastServiceProvider).markRead(b.id, uid);
    }
    _markedRead = true;
  }

  Future<void> _postReply(Broadcast b) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(appUserProvider).whenOrNull(data: (u) => u);
    setState(() => _posting = true);
    try {
      await ref.read(broadcastServiceProvider).postReply(
            BroadcastReply(
              id: '',
              broadcastId: b.id,
              senderUid: user?.uid ?? '',
              senderName: user?.displayName ?? 'Member',
              senderRole: user?.role.name ?? 'player',
              body: text,
              sentAt: DateTime.now(),
            ),
          );
      _replyController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not post reply: $e'),
            backgroundColor: DiabloColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).whenOrNull(data: (u) => u);
    final isAdmin = user?.role == UserRole.admin;
    final isStaff =
        user?.role == UserRole.coach || user?.role == UserRole.admin;
    final muted = ref.watch(currentUserMutedProvider).whenOrNull(data: (m) => m) ??
        false;

    final broadcastAsync =
        ref.watch(broadcastByIdProvider(widget.broadcastId));

    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'BROADCAST',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: broadcastAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DiabloColors.gold),
        ),
        error: (e, _) => Center(
          child: Text('Could not load broadcast.\n$e',
              style: const TextStyle(color: Colors.white54)),
        ),
        data: (broadcast) {
          if (broadcast == null) {
            return const Center(
              child: Text('Broadcast not found.',
                  style: TextStyle(color: Colors.white54)),
            );
          }
          _maybeMarkRead(broadcast);
          final repliesAsync = ref.watch(
            broadcastRepliesProvider(
              (broadcastId: broadcast.id, showDeleted: isAdmin),
            ),
          );

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _header(broadcast, isAdmin),
                    const SizedBox(height: 20),
                    if (broadcast.allowReplies) ...[
                      Row(
                        children: [
                          const Icon(Icons.forum_outlined,
                              color: Colors.white54, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'GROUP REPLIES',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Replies are visible to everyone in this group.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      repliesAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: DiabloColors.gold),
                          ),
                        ),
                        error: (e, _) => Text('$e',
                            style:
                                const TextStyle(color: Colors.white38)),
                        data: (replies) => replies.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No replies yet.',
                                  style: TextStyle(color: Colors.white38),
                                ),
                              )
                            : Column(
                                children: replies
                                    .map((r) => _replyTile(
                                          r,
                                          broadcast,
                                          canModerate: isStaff,
                                          isAdmin: isAdmin,
                                        ))
                                    .toList(),
                              ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: DiabloColors.darkCard,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline,
                                color: Colors.white38, size: 18),
                            SizedBox(width: 10),
                            Text('Replies are turned off for this broadcast.',
                                style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (broadcast.allowReplies)
                _replyComposer(broadcast, muted: muted),
            ],
          );
        },
      ),
    );
  }

  Widget _header(Broadcast b, bool isAdmin) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DiabloColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: b.isUrgent
            ? Border.all(color: DiabloColors.red, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: DiabloColors.red,
                child: Text(
                  b.senderName.isNotEmpty
                      ? b.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.senderName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${b.senderRole} · ${DateFormat.yMMMd().add_jm().format(b.createdAt)}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (b.isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DiabloColors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
          if (b.subject != null) ...[
            const SizedBox(height: 14),
            Text(
              b.subject!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            b.body,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metaPill(Icons.groups, b.audience.summary),
              ...b.channels.map((c) => _metaPill(_channelIcon(c), c.label)),
            ],
          ),
          // Sender + admin see reach + delivery stats.
          if (isAdmin || b.recipientCount > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Sent to ${b.recipientCount} recipient'
              '${b.recipientCount == 1 ? '' : 's'}'
              '${_deliverySuffix(b)}',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _deliverySuffix(Broadcast b) {
    if (b.delivery.isEmpty) return '';
    final parts = b.delivery.entries
        .map((e) => '${e.key} ${e.value.sent}')
        .join(' · ');
    return '  ·  $parts';
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DiabloColors.darkBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DiabloColors.gold),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
        ],
      ),
    );
  }

  Widget _replyTile(
    BroadcastReply r,
    Broadcast b, {
    required bool canModerate,
    required bool isAdmin,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: r.deleted
            ? DiabloColors.darkCard.withValues(alpha: 0.5)
            : DiabloColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: r.deleted
            ? Border.all(color: Colors.white12)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                r.senderName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                r.senderRole,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const Spacer(),
              Text(
                DateFormat.jm().format(r.sentAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              if (canModerate && !r.deleted)
                GestureDetector(
                  onTap: () => _moderate(r, b),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.more_horiz,
                        color: Colors.white38, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (r.deleted)
            Row(
              children: [
                const Icon(Icons.visibility_off,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isAdmin
                        ? 'Removed${r.deletedReason != null ? ' — ${r.deletedReason}' : ''}: “${r.body}”'
                        : 'This reply was removed.',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              r.body,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
        ],
      ),
    );
  }

  void _moderate(BroadcastReply r, Broadcast b) {
    final user = ref.read(appUserProvider).whenOrNull(data: (u) => u);
    showModalBottomSheet(
      context: context,
      backgroundColor: DiabloColors.darkSurface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: DiabloColors.red),
              title: const Text('Remove reply',
                  style: TextStyle(color: Colors.white)),
              subtitle: const Text('Hidden from members, kept for admins',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(broadcastServiceProvider).deleteReply(
                      broadcastId: b.id,
                      replyId: r.id,
                      adminUid: user?.uid ?? '',
                    );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: DiabloColors.gold),
              title: Text('Mute ${r.senderName}',
                  style: const TextStyle(color: Colors.white)),
              subtitle: const Text('Blocks this user from posting replies',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(broadcastServiceProvider).muteUser(
                      uid: r.senderUid,
                      adminUid: user?.uid ?? '',
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${r.senderName} muted'),
                      backgroundColor: DiabloColors.darkCard,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _replyComposer(Broadcast b, {required bool muted}) {
    if (muted) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: DiabloColors.darkSurface,
        child: const Row(
          children: [
            Icon(Icons.block, color: Colors.white38, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'You’ve been muted by an administrator and can’t reply.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: DiabloColors.darkSurface,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                style: const TextStyle(color: Colors.white),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Reply to the group…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: DiabloColors.darkCard,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _posting ? null : () => _postReply(b),
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: DiabloColors.red,
                  shape: BoxShape.circle,
                ),
                child: _posting
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _channelIcon(BroadcastChannel c) {
    switch (c) {
      case BroadcastChannel.push:
        return Icons.notifications;
      case BroadcastChannel.email:
        return Icons.email;
      case BroadcastChannel.sms:
        return Icons.sms;
    }
  }
}
