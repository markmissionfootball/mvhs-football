import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/player.dart';
import '../models/depth_chart.dart';
import '../services/firestore_service.dart';

final rosterProvider =
    FutureProvider.family<List<Player>, String?>((ref, team) async {
  return FirestoreService().getPlayers(team: team);
});

final depthChartsProvider =
    FutureProvider.family<List<DepthChart>, String?>((ref, type) async {
  return FirestoreService().getDepthCharts(type: type);
});
