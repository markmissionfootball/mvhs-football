import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String id;
  final DateTime date;
  final String title;
  final String? description;
  final String phase;
  final String? timeRange;
  final bool allDay;
  final String level;

  const CalendarEvent({
    required this.id,
    required this.date,
    required this.title,
    this.description,
    required this.phase,
    this.timeRange,
    this.allDay = false,
    this.level = 'all',
  });

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      description: data['description'],
      phase: data['phase'] ?? '',
      timeRange: data['timeRange'],
      allDay: data['allDay'] ?? false,
      level: data['level'] ?? 'all',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'title': title,
      'description': description,
      'phase': phase,
      'timeRange': timeRange,
      'allDay': allDay,
      'level': level,
    };
  }
}
