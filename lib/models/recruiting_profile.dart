import 'package:cloud_firestore/cloud_firestore.dart';

class CollegeInterest {
  final String school;
  final String level;
  final String status;
  final String? coachContact;
  final String? notes;

  const CollegeInterest({
    required this.school,
    required this.level,
    required this.status,
    this.coachContact,
    this.notes,
  });

  factory CollegeInterest.fromMap(Map<String, dynamic> data) {
    return CollegeInterest(
      school: data['school'] ?? '',
      level: data['level'] ?? '',
      status: data['status'] ?? 'interested',
      coachContact: data['coachContact'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'school': school,
        'level': level,
        'status': status,
        'coachContact': coachContact,
        'notes': notes,
      };
}

class CampDate {
  final String name;
  final DateTime date;
  final String location;

  const CampDate({
    required this.name,
    required this.date,
    required this.location,
  });

  factory CampDate.fromMap(Map<String, dynamic> data) {
    return CampDate(
      name: data['name'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'date': Timestamp.fromDate(date),
        'location': location,
      };
}

class RecruitingProfile {
  final String playerId;
  final double? gpa;
  final int? satScore;
  final int? actScore;
  final String? ncaaId;
  final List<String> highlightVideoUrls;
  final List<CollegeInterest> collegeInterests;
  final List<CampDate> campDates;

  const RecruitingProfile({
    required this.playerId,
    this.gpa,
    this.satScore,
    this.actScore,
    this.ncaaId,
    this.highlightVideoUrls = const [],
    this.collegeInterests = const [],
    this.campDates = const [],
  });

  factory RecruitingProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecruitingProfile(
      playerId: data['playerId'] ?? doc.id,
      gpa: (data['gpa'] as num?)?.toDouble(),
      satScore: data['satScore'],
      actScore: data['actScore'],
      ncaaId: data['ncaaId'],
      highlightVideoUrls:
          List<String>.from(data['highlightVideoUrls'] ?? []),
      collegeInterests: (data['collegeInterests'] as List<dynamic>?)
              ?.map(
                  (c) => CollegeInterest.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      campDates: (data['campDates'] as List<dynamic>?)
              ?.map((c) => CampDate.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'playerId': playerId,
      'gpa': gpa,
      'satScore': satScore,
      'actScore': actScore,
      'ncaaId': ncaaId,
      'highlightVideoUrls': highlightVideoUrls,
      'collegeInterests': collegeInterests.map((c) => c.toMap()).toList(),
      'campDates': campDates.map((c) => c.toMap()).toList(),
    };
  }
}
