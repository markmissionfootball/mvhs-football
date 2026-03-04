import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../providers/auth_provider.dart';
import '../../theme/diablo_colors.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../../services/e2e_crypto_service.dart';
import '../../widgets/chat_bubble.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const ChatRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _crypto = E2eCryptoService();
  final _speech = stt.SpeechToText();

  String get _currentUid => ref.watch(currentUidProvider);
  String get _currentName => ref.watch(appUserProvider).valueOrNull?.displayName ?? 'Me';

  ChatRoom? _room;
  final Map<String, String> _decryptedMessages = {};
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadRoom();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        setState(() => _isListening = false);
      },
    );
  }

  Future<void> _loadRoom() async {
    final doc = await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .get();
    if (doc.exists) {
      setState(() {
        _room = ChatRoom.fromFirestore(doc);
      });
    }
  }

  Future<String> _decryptIfNeeded(ChatMessage msg) async {
    if (_decryptedMessages.containsKey(msg.id)) {
      return _decryptedMessages[msg.id]!;
    }

    try {
      final privateKey = await _crypto.loadPrivateKey();
      if (privateKey == null || _room == null) return '[encryption key missing]';

      final roomKey = await _crypto.getRoomKey(
        roomId: widget.roomId,
        encryptedKeys: _room!.encryptedKeys,
        currentUid: _currentUid,
        privateKeyBase64: privateKey,
      );

      final plaintext = await _crypto.decryptMessage(
        ciphertextBase64: msg.ciphertext,
        nonceBase64: msg.nonce,
        roomKey: roomKey,
      );

      _decryptedMessages[msg.id] = plaintext;
      return plaintext;
    } catch (_) {
      return '[unable to decrypt]';
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _room == null) return;

    _textController.clear();

    try {
      final privateKey = await _crypto.loadPrivateKey();
      if (privateKey == null) return;

      final roomKey = await _crypto.getRoomKey(
        roomId: widget.roomId,
        encryptedKeys: _room!.encryptedKeys,
        currentUid: _currentUid,
        privateKeyBase64: privateKey,
      );

      final encrypted = await _crypto.encryptMessage(
        plaintext: text,
        roomKey: roomKey,
      );

      final message = ChatMessage(
        id: '',
        senderUid: _currentUid,
        senderName: _currentName,
        ciphertext: encrypted.ciphertext,
        nonce: encrypted.nonce,
        sentAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.roomId)
          .collection('messages')
          .add(message.toFirestore());
    } catch (_) {
      // TODO: Show error snackbar
    }
  }

  void _toggleVoiceInput() async {
    if (!_speechAvailable) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
          if (result.finalResult) {
            setState(() => _isListening = false);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomName = _room?.displayName(_currentUid) ?? 'Chat';
    final isGroup = _room?.type == ChatRoomType.group;

    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isGroup ? Icons.groups : Icons.person,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                roomName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => context.push('/chat/${widget.roomId}/info'),
            ),
        ],
      ),
      body: Column(
        children: [
          // E2E encryption badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: DiabloColors.darkSurface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 12,
                  color: DiabloColors.gold.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  'End-to-end encrypted',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.roomId)
                  .collection('messages')
                  .orderBy('sentAt', descending: false)
                  .limitToLast(100)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: DiabloColors.gold),
                  );
                }

                final messages = snapshot.data?.docs
                        .map((doc) => ChatMessage.fromFirestore(doc))
                        .toList() ??
                    [];

                if (messages.isNotEmpty) {
                  _scrollToBottom();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderUid == _currentUid;

                    return FutureBuilder<String>(
                      future: _decryptIfNeeded(msg),
                      builder: (context, snap) {
                        final text = snap.data ?? '...';
                        return ChatBubble(
                          message: text,
                          isUser: isMe,
                          senderName: isMe ? null : msg.senderName.toUpperCase(),
                          timestamp:
                              DateFormat.jm().format(msg.sentAt),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        color: DiabloColors.darkSurface,
        child: Row(
          children: [
            // Voice input button
            GestureDetector(
              onTap: _toggleVoiceInput,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isListening
                      ? DiabloColors.red
                      : Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.white : DiabloColors.gold,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Text field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _isListening ? 'Listening...' : 'Message...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: DiabloColors.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  color: DiabloColors.red,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
