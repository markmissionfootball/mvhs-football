import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/diablo_colors.dart';
import '../../models/chat_room.dart';
import '../../models/user.dart';
import '../../services/e2e_crypto_service.dart';
import '../../widgets/player_picker_tile.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final _searchController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _crypto = E2eCryptoService();

  String get _currentUid => ref.watch(currentUidProvider);
  String get _currentName => ref.watch(appUserProvider).valueOrNull?.displayName ?? 'Me';

  List<AppUser> _allPlayers = [];
  final Set<String> _selectedUids = {};
  bool _loading = true;
  bool _creating = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'player')
        .get();

    setState(() {
      _allPlayers = snap.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where((u) => u.uid != _currentUid)
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      _loading = false;
    });
  }

  List<AppUser> get _filteredPlayers {
    if (_searchQuery.isEmpty) return _allPlayers;
    final q = _searchQuery.toLowerCase();
    return _allPlayers
        .where((p) => p.displayName.toLowerCase().contains(q))
        .toList();
  }

  bool get _isGroup => _selectedUids.length > 1;

  void _togglePlayer(String uid) {
    setState(() {
      if (_selectedUids.contains(uid)) {
        _selectedUids.remove(uid);
      } else {
        _selectedUids.add(uid);
      }
    });
  }

  Future<void> _createChat() async {
    if (_selectedUids.isEmpty || _creating) return;
    setState(() => _creating = true);

    try {
      final allUids = [_currentUid, ..._selectedUids];
      final isGroup = _selectedUids.length > 1;

      // For DMs, check if one already exists
      if (!isGroup) {
        final existing = await _findExistingDm(allUids);
        if (existing != null && mounted) {
          context.go('/chat/$existing');
          return;
        }
      }

      // Generate room key and encrypt for each participant
      final roomKey = await _crypto.generateRoomKey();
      final encryptedKeys = <EncryptedRoomKey>[];

      for (final uid in allUids) {
        final user = uid == _currentUid
            ? null
            : _allPlayers.where((p) => p.uid == uid).firstOrNull;

        // Get public key from Firestore
        final userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final pubKey = userDoc.data()?['e2ePublicKey'] as String?;

        if (pubKey == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${user?.displayName ?? "A player"} hasn\'t set up encryption yet.'),
                backgroundColor: DiabloColors.red,
              ),
            );
          }
          setState(() => _creating = false);
          return;
        }

        final encrypted = await _crypto.encryptRoomKeyForRecipient(
          roomKey: roomKey,
          recipientUid: uid,
          recipientPublicKeyBase64: pubKey,
        );
        encryptedKeys.add(encrypted);
      }

      // Build participant names map
      final participantNames = <String, String>{
        _currentUid: _currentName,
      };
      for (final uid in _selectedUids) {
        final user = _allPlayers.where((p) => p.uid == uid).firstOrNull;
        if (user != null) {
          participantNames[uid] = user.displayName;
        }
      }

      final room = ChatRoom(
        id: '',
        type: isGroup ? ChatRoomType.group : ChatRoomType.dm,
        name: isGroup ? _groupNameController.text.trim() : null,
        participantUids: allUids,
        participantNames: participantNames,
        encryptedKeys: encryptedKeys,
        createdBy: _currentUid,
        createdAt: DateTime.now(),
      );

      final docRef = await FirebaseFirestore.instance
          .collection('chatRooms')
          .add(room.toFirestore());

      if (mounted) {
        context.go('/chat/${docRef.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create chat: $e'),
            backgroundColor: DiabloColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<String?> _findExistingDm(List<String> uids) async {
    final snap = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('type', isEqualTo: 'dm')
        .where('participantUids', arrayContains: _currentUid)
        .get();

    for (final doc in snap.docs) {
      final room = ChatRoom.fromFirestore(doc);
      if (room.participantUids.length == 2 &&
          room.participantUids.contains(uids[0]) &&
          room.participantUids.contains(uids[1])) {
        return doc.id;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'NEW MESSAGE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(12),
            color: DiabloColors.darkSurface,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search players...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Selected count + group name
          if (_selectedUids.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: DiabloColors.darkCard,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        '${_selectedUids.length} selected',
                        style: const TextStyle(
                          color: DiabloColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (_isGroup)
                        const Text(
                          'GROUP CHAT',
                          style: TextStyle(
                            color: DiabloColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                    ],
                  ),
                  if (_isGroup) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _groupNameController,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Group name (optional)',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Player list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: DiabloColors.gold),
                  )
                : ListView.builder(
                    itemCount: _filteredPlayers.length,
                    itemBuilder: (context, index) {
                      final player = _filteredPlayers[index];
                      return PlayerPickerTile(
                        playerName: player.displayName,
                        position: null,
                        isSelected: _selectedUids.contains(player.uid),
                        onTap: () => _togglePlayer(player.uid),
                      );
                    },
                  ),
          ),
          // Create button
          if (_selectedUids.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _creating ? null : _createChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DiabloColors.gold,
                      foregroundColor: DiabloColors.dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _creating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: DiabloColors.dark,
                            ),
                          )
                        : Text(
                            _isGroup ? 'CREATE GROUP' : 'START CHAT',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
