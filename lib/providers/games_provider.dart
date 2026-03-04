import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game.dart';
import '../services/firestore_service.dart';

final gamesProvider =
    FutureProvider.family<List<Game>, String?>((ref, level) async {
  return FirestoreService().getGames(level: level);
});
