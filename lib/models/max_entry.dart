import 'package:cloud_firestore/cloud_firestore.dart';

class MaxEntry {
  final DateTime date;
  final String type;
  final double? clean;
  final double? squat;
  final double? bench;
  final double? incline;
  final double? total;
  final double? bodyWeight;

  const MaxEntry({
    required this.date,
    required this.type,
    this.clean,
    this.squat,
    this.bench,
    this.incline,
    this.total,
    this.bodyWeight,
  });

  factory MaxEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MaxEntry(
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? '',
      clean: (data['clean'] as num?)?.toDouble(),
      squat: (data['squat'] as num?)?.toDouble(),
      bench: (data['bench'] as num?)?.toDouble(),
      incline: (data['incline'] as num?)?.toDouble(),
      total: (data['total'] as num?)?.toDouble(),
      bodyWeight: (data['bodyWeight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'type': type,
      'clean': clean,
      'squat': squat,
      'bench': bench,
      'incline': incline,
      'total': total,
      'bodyWeight': bodyWeight,
    };
  }
}
