import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String ciphertext;
  final String nonce;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.ciphertext,
    required this.nonce,
    required this.sentAt,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderUid: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? '',
      ciphertext: data['ciphertext'] ?? '',
      nonce: data['nonce'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderUid': senderUid,
      'senderName': senderName,
      'ciphertext': ciphertext,
      'nonce': nonce,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }
}
