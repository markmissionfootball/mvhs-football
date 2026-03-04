import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String author;
  final String audienceLevel;
  final String priority;
  final DateTime createdAt;
  final List<String> readBy;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    this.audienceLevel = 'all',
    this.priority = 'normal',
    required this.createdAt,
    this.readBy = const [],
  });

  bool get isUrgent => priority == 'urgent';

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      author: data['author'] ?? '',
      audienceLevel: data['audienceLevel'] ?? 'all',
      priority: data['priority'] ?? 'normal',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'body': body,
      'author': author,
      'audienceLevel': audienceLevel,
      'priority': priority,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }
}
