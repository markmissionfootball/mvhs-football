import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/broadcast.dart';
import '../../models/broadcast_reply.dart';
import '../../providers/broadcast_provider.dart';
import '../../theme/diablo_colors.dart';

/// Administrator oversight surface: every broadcast across the program and the
/// append-only audit log. This is the compliance backbone — admins can see all
/// communications (including removed replies) and the full action history.
class BroadcastOversightScreen extends ConsumerWidget {
  const BroadcastOversightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: DiabloColors.darkBackground,
        appBar: AppBar(
          backgroundColor: DiabloColors.red,
          title: const Text(
            'MESSAGE OVERSIGHT',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: DiabloColors.gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [Tab(text: 'ALL BROADCASTS'), Tab(text: 'AUDIT LOG')],
          ),
        ),
        body: const TabBarView(
          children: [_AllBroadcastsTab(), _AuditLogTab()],
        ),
      ),
    );
  }
}

class _AllBroadcastsTab extends ConsumerWidget {
  const _AllBroadcastsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(broadcastAllProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DiabloColors.gold),
      ),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: Colors.white54)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('No broadcasts sent yet.',
                style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final b = items[i];
            return GestureDetector(
              onTap: () => context.push('/broadcasts/${b.id}'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DiabloColors.darkCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            b.subject ?? b.preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (b.isUrgent)
                          const Icon(Icons.priority_high,
                              color: DiabloColors.red, size: 16),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${b.senderName} (${b.senderRole}) → ${b.audience.summary}',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.groups, color: Colors.white38, size: 13),
                        const SizedBox(width: 4),
                        Text('${b.recipientCount}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11.5)),
                        const SizedBox(width: 12),
                        ...b.channels.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(c.label,
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11.5)),
                            )),
                        const Spacer(),
                        Text(
                          DateFormat.MMMd().add_jm().format(b.createdAt),
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AuditLogTab extends ConsumerWidget {
  const _AuditLogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(messageAuditProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DiabloColors.gold),
      ),
      error: (e, _) => Center(
        child: Text('$e', style: const TextStyle(color: Colors.white54)),
      ),
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Text('No activity logged yet.',
                style: TextStyle(color: Colors.white54)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(
            color: Colors.white12,
            height: 20,
          ),
          itemBuilder: (context, i) => _auditRow(events[i]),
        );
      },
    );
  }

  Widget _auditRow(MessageAuditEvent e) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_iconFor(e.type), size: 18, color: _colorFor(e.type)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _detail(e),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          DateFormat.MMMd().add_jm().format(e.at),
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }

  String _detail(MessageAuditEvent e) {
    final actor = e.actorName.isNotEmpty ? e.actorName : e.actorUid;
    switch (e.type) {
      case 'broadcast_sent':
        final count = e.meta['recipientCount'] ?? '?';
        return '$actor sent to $count recipients';
      case 'reply_posted':
        return '$actor replied';
      case 'reply_deleted':
        return 'Reply removed${e.meta['reason'] != null ? ' — ${e.meta['reason']}' : ''}';
      case 'user_muted':
        return 'Muted a user${e.meta['reason'] != null ? ' — ${e.meta['reason']}' : ''}';
      case 'user_unmuted':
        return 'Unmuted a user';
      default:
        return actor;
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'broadcast_sent':
        return Icons.campaign;
      case 'reply_posted':
        return Icons.reply;
      case 'reply_deleted':
        return Icons.delete_outline;
      case 'user_muted':
        return Icons.block;
      case 'user_unmuted':
        return Icons.check_circle_outline;
      default:
        return Icons.circle;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'reply_deleted':
      case 'user_muted':
        return DiabloColors.red;
      case 'broadcast_sent':
        return DiabloColors.gold;
      default:
        return Colors.white54;
    }
  }
}
