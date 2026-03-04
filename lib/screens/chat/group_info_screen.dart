import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/diablo_colors.dart';
import '../../models/chat_room.dart';

class GroupInfoScreen extends ConsumerStatefulWidget {
  final String roomId;

  const GroupInfoScreen({super.key, required this.roomId});

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen> {
  String get _currentUid => ref.watch(currentUidProvider);

  ChatRoom? _room;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    final doc = await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .get();
    if (doc.exists) {
      setState(() {
        _room = ChatRoom.fromFirestore(doc);
        _loading = false;
      });
    }
  }

  Future<void> _leaveGroup() async {
    if (_room == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DiabloColors.darkCard,
        title: const Text(
          'Leave Group',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You will no longer receive messages from this group.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: DiabloColors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .update({
      'participantUids': FieldValue.arrayRemove([_currentUid]),
    });

    if (mounted) {
      context.go('/profile/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'GROUP INFO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: DiabloColors.gold),
            )
          : _room == null
              ? const Center(
                  child: Text('Group not found',
                      style: TextStyle(color: Colors.white54)),
                )
              : ListView(
                  children: [
                    // Group header
                    Container(
                      padding: const EdgeInsets.all(24),
                      color: DiabloColors.darkSurface,
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: DiabloColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.groups,
                                color: DiabloColors.dark,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _room!.name ?? 'Group Chat',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_room!.participantUids.length} members',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Members section header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'MEMBERS',
                        style: TextStyle(
                          color: DiabloColors.gold.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    // Member list
                    ..._room!.participantUids.map((uid) {
                      final name =
                          _room!.participantNames[uid] ?? 'Unknown';
                      final isMe = uid == _currentUid;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: DiabloColors.darkCard,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: DiabloColors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isMe ? '$name (You)' : name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (uid == _room!.createdBy)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: DiabloColors.gold),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: DiabloColors.gold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    // Leave group button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: OutlinedButton.icon(
                        onPressed: _leaveGroup,
                        icon: const Icon(Icons.exit_to_app,
                            color: DiabloColors.red),
                        label: const Text(
                          'LEAVE GROUP',
                          style: TextStyle(
                            color: DiabloColors.red,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DiabloColors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }
}
