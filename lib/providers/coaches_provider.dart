import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coach.dart';
import '../services/firestore_service.dart';

final coachesProvider = FutureProvider<List<Coach>>((ref) async {
  return FirestoreService().getCoaches();
});
