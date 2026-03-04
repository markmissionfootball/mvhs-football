import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/announcement.dart';
import '../services/firestore_service.dart';

final announcementsProvider = StreamProvider<List<Announcement>>((ref) {
  return FirestoreService().streamAnnouncements();
});
