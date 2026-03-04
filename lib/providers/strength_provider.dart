import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout.dart';
import '../models/max_entry.dart';
import '../services/firestore_service.dart';

final currentWorkoutProvider = FutureProvider<WorkoutProgram?>((ref) async {
  return FirestoreService().getCurrentWorkout();
});

final maxEntriesProvider =
    FutureProvider.family<List<MaxEntry>, String>((ref, playerId) async {
  return FirestoreService().getMaxEntries(playerId);
});
