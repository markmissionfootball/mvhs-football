import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../theme/diablo_colors.dart';
import '../../models/chat_room.dart';
import '../../widgets/chat_room_tile.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String get _currentUid => ref.watch(currentUidProvider);

  Stream<QuerySnapshot>? _stream;
  bool _streamError = false;

  @override
  void initState() {
    super.initState();
    try {
      _stream = FirebaseFirestore.instance
          .collection('chatRooms')
          .where('participantUids', arrayContains: _currentUid)
          .orderBy('lastMessageAt', descending: true)
          .snapshots()
          .handleError((_) {
        if (mounted) setState(() => _streamError = true);
      });
    } catch (_) {
      _streamError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'MESSAGES',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: _streamError || _stream == null
          ? _buildEmptyState(context)
          : StreamBuilder<QuerySnapshot>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildEmptyState(context);
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: DiabloColors.gold),
                  );
                }

                final rooms = snapshot.data?.docs
                        .map((doc) => ChatRoom.fromFirestore(doc))
                        .toList() ??
                    [];

                if (rooms.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return ChatRoomTile(
                      roomName: room.displayName(_currentUid),
                      lastMessageTime: room.lastMessageAt != null
                          ? _formatTime(room.lastMessageAt!)
                          : null,
                      isGroup: room.type == ChatRoomType.group,
                      onTap: () => context.push('/chat/${room.id}'),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DiabloColors.gold,
        onPressed: () => context.push('/chat/new'),
        child: const Icon(
          Icons.edit,
          color: DiabloColors.dark,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'NO MESSAGES YET',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with a teammate',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return DateFormat.jm().format(dt);
    if (diff.inDays < 7) return DateFormat.E().format(dt);
    return DateFormat.MMMd().format(dt);
  }
}
