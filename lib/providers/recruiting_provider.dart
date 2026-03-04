import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recruiting_profile.dart';
import '../services/firestore_service.dart';

final recruitingProfileProvider =
    FutureProvider.family<RecruitingProfile?, String>((ref, playerId) async {
  return FirestoreService().getRecruitingProfile(playerId);
});
