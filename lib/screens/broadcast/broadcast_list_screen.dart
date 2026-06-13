import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/broadcast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/broadcast_provider.dart';
import '../../theme/diablo_colors.dart';

/// Inbox of broadcasts addressed to the current user, plus a "Sent" tab for
/// coaches/admins to review what they've sent. Staff see a compose FAB.
class BroadcastListScreen extends ConsumerWidget {
  const BroadcastListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).whenOrNull(data: (u) => u);
    final isStaff = user != null &&
        (user.role == UserRole.coach || user.role == UserRole.admin);

    return DefaultTabController(
      length: isStaff ? 2 : 1,
      child: Scaffold(
        backgroundColor: DiabloColors.darkBackground,
        appBar: AppBar(
          backgroundColor: DiabloColors.red,
          title: const Text(
            'BROADCASTS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          bottom: isStaff
              ? const TabBar(
                  indicatorColor: DiabloColors.gold,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: [Tab(text: 'INBOX'), Tab(text: 'SENT')],
                )
              : null,
        ),
        body: TabBarView(
          children: [
            _BroadcastListView(provider: broadcastInboxProvider),
            if (isStaff)
              _BroadcastListView(
                provider: broadcastSentProvider,
                emptyLabel: 'You haven’t sent any broadcasts yet.',
              ),
          ],
        ),
        floatingActionButton: isStaff
            ? FloatingActionButton.extended(
                backgroundColor: DiabloColors.gold,
                foregroundColor: Colors.black,
                onPressed: () => context.push('/broadcasts/new'),
                icon: const Icon(Icons.campaign),
                label: const Text(
                  'NEW',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            : null,
      ),
    );
  }
}

class _BroadcastListView extends ConsumerWidget {
  const _BroadcastListView({
    required this.provider,
    this.emptyLabel = 'No broadcasts yet.',
  });

  final ProviderListenable<AsyncValue<List<Broadcast>>> provider;
  final String emptyLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DiabloColors.gold),
      ),
      error: (e, _) => Center(
        child: Text(
          'Could not load broadcasts.\n$e',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.campaign_outlined,
                      color: Colors.white24, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    emptyLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _BroadcastTile(broadcast: items[i]),
        );
      },
    );
  }
}

class _BroadcastTile extends ConsumerWidget {
  const _BroadcastTile({required this.broadcast});

  final Broadcast broadcast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUidProvider);
    final unread = !broadcast.readBy.contains(uid);
    return GestureDetector(
      onTap: () => context.push('/broadcasts/${broadcast.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DiabloColors.darkCard,
          borderRadius: BorderRadius.circular(8),
          border: broadcast.isUrgent
              ? Border.all(color: DiabloColors.red, width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (broadcast.isUrgent) ...[
                  const Icon(Icons.priority_high,
                      color: DiabloColors.red, size: 16),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    broadcast.subject ?? broadcast.senderName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          unread ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (unread)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: DiabloColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              broadcast.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.groups, color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  broadcast.audience.summary,
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
                const Spacer(),
                Text(
                  _fmt(broadcast.createdAt),
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat.jm().format(dt);
    }
    return DateFormat.MMMd().format(dt);
  }
}
