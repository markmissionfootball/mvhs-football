import 'package:cloud_firestore/cloud_firestore.dart';

class Certification {
  final String name;
  final String status;
  final DateTime? expiry;

  const Certification({
    required this.name,
    required this.status,
    this.expiry,
  });

  factory Certification.fromMap(Map<String, dynamic> data) {
    return Certification(
      name: data['name'] ?? '',
      status: data['status'] ?? '',
      expiry: (data['expiry'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
        'expiry': expiry != null ? Timestamp.fromDate(expiry!) : null,
      };
}

class Coach {
  final String id;
  final String firstName;
  final String lastName;
  final String title;
  final String positionGroup;
  final String? email;
  final String? phone;
  final List<Certification> certifications;
  final bool active;

  const Coach({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.positionGroup,
    this.email,
    this.phone,
    this.certifications = const [],
    this.active = true,
  });

  String get fullName => '$firstName $lastName';

  factory Coach.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coach(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      title: data['title'] ?? '',
      positionGroup: data['positionGroup'] ?? '',
      email: data['email'],
      phone: data['phone'],
      certifications: (data['certifications'] as List<dynamic>?)
              ?.map((c) => Certification.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      active: data['active'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'title': title,
      'positionGroup': positionGroup,
      'email': email,
      'phone': phone,
      'certifications': certifications.map((c) => c.toMap()).toList(),
      'active': active,
    };
  }
}
