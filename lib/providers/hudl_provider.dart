import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hudl_film.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'demo_data.dart';

/// All game films for the team, sorted by date descending.
final hudlFilmsProvider = FutureProvider<List<HudlFilm>>((ref) async {
  return FirestoreService().getHudlFilms();
});

/// All films for a specific player (where they are tagged in plays).
final playerFilmsProvider =
    FutureProvider.family<List<HudlFilm>, String>((ref, playerId) async {
  return FirestoreService().getPlayerFilms(playerId);
});

/// Play breakdown for a specific film.
final filmPlaysProvider =
    FutureProvider.family<List<HudlPlay>, String>((ref, filmId) async {
  return FirestoreService().getFilmPlays(filmId);
});

/// Player stats for a specific film.
final filmPlayerStatsProvider =
    FutureProvider.family<List<HudlPlayerStats>, String>((ref, filmId) async {
  return FirestoreService().getFilmPlayerStats(filmId);
});

/// A single player's stats across all films (career view).
final playerFilmStatsProvider =
    FutureProvider.family<List<HudlPlayerStats>, String>((ref, playerId) async {
  return FirestoreService().getPlayerFilmStats(playerId);
});

/// Current player's film stats (convenience).
final myFilmStatsProvider = FutureProvider<List<HudlPlayerStats>>((ref) async {
  final appUser =
      ref.watch(appUserProvider).whenOrNull(data: (u) => u);
  final playerId = appUser?.linkedPlayerId;
  if (playerId == null || playerId.isEmpty) {
    return DemoData.hudlPlayerStats;
  }
  return FirestoreService().getPlayerFilmStats(playerId);
});

/// Current player's film list (convenience).
final myFilmsProvider = FutureProvider<List<HudlFilm>>((ref) async {
  final appUser =
      ref.watch(appUserProvider).whenOrNull(data: (u) => u);
  final playerId = appUser?.linkedPlayerId;
  if (playerId == null || playerId.isEmpty) {
    return DemoData.hudlFilms;
  }
  return FirestoreService().getPlayerFilms(playerId);
});
