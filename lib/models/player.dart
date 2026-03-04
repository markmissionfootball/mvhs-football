import 'package:cloud_firestore/cloud_firestore.dart';

class ParentContact {
  final String name;
  final String email;
  final String phone;

  const ParentContact({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory ParentContact.fromMap(Map<String, dynamic> data) {
    return ParentContact(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
      };
}

class PaymentStatus {
  final bool springBall;
  final bool summerBall;
  final bool contributionFee;
  final bool blastContacts;

  const PaymentStatus({
    this.springBall = false,
    this.summerBall = false,
    this.contributionFee = false,
    this.blastContacts = false,
  });

  factory PaymentStatus.fromMap(Map<String, dynamic> data) {
    return PaymentStatus(
      springBall: data['springBall'] ?? false,
      summerBall: data['summerBall'] ?? false,
      contributionFee: data['contributionFee'] ?? false,
      blastContacts: data['blastContacts'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'springBall': springBall,
        'summerBall': summerBall,
        'contributionFee': contributionFee,
        'blastContacts': blastContacts,
      };
}

class Player {
  final String id;
  final String firstName;
  final String lastName;
  final int grade;
  final String position;
  final int? jerseyNumber;
  final String team; // "varsity", "jv", "freshman"
  final String? height;
  final int? weight;
  final Map<String, String> sizes;
  final String athleticClearance;
  final String? clearanceNotes;
  final PaymentStatus paymentStatus;
  final ParentContact? parentContact;
  final bool active;
  final DateTime updatedAt;

  const Player({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.grade,
    required this.position,
    this.jerseyNumber,
    required this.team,
    this.height,
    this.weight,
    this.sizes = const {},
    this.athleticClearance = 'pending',
    this.clearanceNotes,
    this.paymentStatus = const PaymentStatus(),
    this.parentContact,
    this.active = true,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Player.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Player(
      id: doc.id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      grade: data['grade'] ?? 9,
      position: data['position'] ?? '',
      jerseyNumber: data['jerseyNumber'],
      team: data['team'] ?? 'freshman',
      height: data['height'],
      weight: data['weight'],
      sizes: Map<String, String>.from(data['sizes'] ?? {}),
      athleticClearance: data['athleticClearance'] ?? 'pending',
      clearanceNotes: data['clearanceNotes'],
      paymentStatus:
          PaymentStatus.fromMap(data['paymentStatus'] as Map<String, dynamic>? ?? {}),
      parentContact: data['parentContact'] != null
          ? ParentContact.fromMap(data['parentContact'] as Map<String, dynamic>)
          : null,
      active: data['active'] ?? true,
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'grade': grade,
      'position': position,
      'jerseyNumber': jerseyNumber,
      'team': team,
      'height': height,
      'weight': weight,
      'sizes': sizes,
      'athleticClearance': athleticClearance,
      'clearanceNotes': clearanceNotes,
      'paymentStatus': paymentStatus.toMap(),
      'parentContact': parentContact?.toMap(),
      'active': active,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
