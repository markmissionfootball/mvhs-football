import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/coach.dart';
import '../models/announcement.dart';
import '../models/calendar_event.dart';
import '../models/workout.dart';
import '../models/max_entry.dart';
import '../models/depth_chart.dart';
import '../models/recruiting_profile.dart';
import '../models/game_stat.dart';
import '../providers/demo_data.dart';
import 'package:flutter/foundation.dart';
import '../models/invite.dart';
import '../models/user.dart';
import '../models/hudl_film.dart';

/// Centralized Firestore service. Every method wraps Firestore calls in
/// try-catch and returns null/empty list on failure, falling back to DemoData
/// when available.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._();
  factory FirestoreService() => _instance;
  FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Games ──────────────────────────────────────────────────────────

  Future<List<Game>> getGames({String? level}) async {
    try {
      Query query = _db.collection('games').orderBy('date');
      if (level != null) {
        query = query.where('level', isEqualTo: level);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Game.fromFirestore(doc)).toList();
    } catch (e) {
      return DemoData.games;
    }
  }

  // ── Players ────────────────────────────────────────────────────────

  Future<List<Player>> getPlayers({String? team, bool activeOnly = true}) async {
    try {
      Query query = _db.collection('players');
      if (team != null) {
        query = query.where('team', isEqualTo: team);
      }
      if (activeOnly) {
        query = query.where('active', isEqualTo: true);
      }
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => Player.fromFirestore(doc)).toList();
    } catch (e) {
      return DemoData.roster;
    }
  }

  // ── Coaches ────────────────────────────────────────────────────────

  Future<List<Coach>> getCoaches() async {
    try {
      final snapshot = await _db.collection('coaches').get();
      return snapshot.docs.map((doc) => Coach.fromFirestore(doc)).toList();
    } catch (e) {
      return DemoData.coaches;
    }
  }

  // ── Announcements ──────────────────────────────────────────────────

  Future<List<Announcement>> getAnnouncements({int limit = 10}) async {
    try {
      final snapshot = await _db
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => Announcement.fromFirestore(doc))
          .toList();
    } catch (e) {
      return DemoData.announcements;
    }
  }

  Stream<List<Announcement>> streamAnnouncements({int limit = 5}) {
    try {
      return _db
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Announcement.fromFirestore(doc))
              .toList());
    } catch (e) {
      return Stream.value(DemoData.announcements);
    }
  }

  // ── Calendar Events ────────────────────────────────────────────────

  Future<List<CalendarEvent>> getCalendarEvents() async {
    try {
      final snapshot = await _db.collection('calendarEvents').get();
      return snapshot.docs
          .map((doc) => CalendarEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      return DemoData.calendarEvents;
    }
  }

  // ── Workout Program ────────────────────────────────────────────────

  Future<WorkoutProgram?> getCurrentWorkout() async {
    try {
      final snapshot =
          await _db.collection('workoutPrograms').limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      return WorkoutProgram.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return DemoData.workout;
    }
  }

  // ── Max Entries ────────────────────────────────────────────────────

  Future<List<MaxEntry>> getMaxEntries(String playerId) async {
    try {
      final snapshot = await _db
          .collection('players')
          .doc(playerId)
          .collection('maxEntries')
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => MaxEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      return DemoData.maxEntries;
    }
  }

  // ── Depth Charts ───────────────────────────────────────────────────

  Future<List<DepthChart>> getDepthCharts({String? type}) async {
    try {
      Query query = _db.collection('depthCharts');
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => DepthChart.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Recruiting Profile ─────────────────────────────────────────────

  Future<RecruitingProfile?> getRecruitingProfile(String playerId) async {
    try {
      final doc =
          await _db.collection('recruitingProfiles').doc(playerId).get();
      if (!doc.exists) return null;
      return RecruitingProfile.fromFirestore(doc);
    } catch (e) {
      return null;
    }
  }

  // ── Game Stats ─────────────────────────────────────────────────────

  Future<List<DefensiveStat>> getGameStats(String playerId) async {
    try {
      final snapshot = await _db
          .collection('players')
          .doc(playerId)
          .collection('gameStats')
          .get();
      return snapshot.docs
          .map((doc) => DefensiveStat.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── Auth / Invites ───────────────────────────────────────────────

  /// Look up a user document by username field.
  Future<AppUser?> getUserByUsername(String username) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return AppUser.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Look up a user document by email.
  Future<AppUser?> getUserByEmail(String email) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return AppUser.fromFirestore(snapshot.docs.first);
    } catch (e) {
      return null;
    }
  }

  /// Validate an invite code for registration.
  Future<Invite?> validateInviteCode(String email, String code) async {
    try {
      final snapshot = await _db
          .collection('invites')
          .where('email', isEqualTo: email.toLowerCase())
          .where('inviteCode', isEqualTo: code)
          .where('claimed', isEqualTo: false)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      final invite = Invite.fromFirestore(snapshot.docs.first);
      if (invite.expiresAt.isBefore(DateTime.now())) return null;
      return invite;
    } catch (e) {
      return null;
    }
  }

  /// Mark an invite as claimed.
  Future<void> claimInvite(String inviteId, String uid) async {
    try {
      await _db.collection('invites').doc(inviteId).update({
        'claimed': true,
        'claimedAt': Timestamp.now(),
        'claimedByUid': uid,
      });
    } catch (e) {
      debugPrint('Failed to claim invite: $e');
    }
  }

  /// Create a new invite (admin action).
  Future<String?> createInvite(Invite invite) async {
    try {
      final docRef = await _db.collection('invites').add(invite.toFirestore());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Update user document fields.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      debugPrint('Failed to update user: $e');
    }
  }

  /// Create a new user document in Firestore.
  Future<void> createUserDocument(AppUser user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toFirestore());
    } catch (e) {
      debugPrint('Failed to create user doc: $e');
    }
  }

  // ── Hudl Film ──────────────────────────────────────────────────────

  /// Get all game films, sorted by game date descending.
  Future<List<HudlFilm>> getHudlFilms() async {
    try {
      final snapshot = await _db
          .collection('hudlFilms')
          .orderBy('gameDate', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => HudlFilm.fromFirestore(doc))
          .toList();
    } catch (e) {
      return DemoData.hudlFilms;
    }
  }

  /// Get films where a specific player is tagged.
  Future<List<HudlFilm>> getPlayerFilms(String playerId) async {
    try {
      // First get all filmIds where this player has stats
      final statsSnapshot = await _db
          .collection('hudlPlayerStats')
          .where('playerId', isEqualTo: playerId)
          .get();
      final filmIds = statsSnapshot.docs
          .map((doc) => (doc.data())['filmId'] as String)
          .toSet()
          .toList();

      if (filmIds.isEmpty) return DemoData.hudlFilms;

      final filmSnapshot = await _db
          .collection('hudlFilms')
          .where(FieldPath.documentId, whereIn: filmIds)
          .get();
      final films = filmSnapshot.docs
          .map((doc) => HudlFilm.fromFirestore(doc))
          .toList();
      films.sort((a, b) => b.gameDate.compareTo(a.gameDate));
      return films;
    } catch (e) {
      return DemoData.hudlFilms;
    }
  }

  /// Get play-by-play breakdown for a film.
  Future<List<HudlPlay>> getFilmPlays(String filmId) async {
    try {
      final snapshot = await _db
          .collection('hudlFilms')
          .doc(filmId)
          .collection('plays')
          .orderBy('playNumber')
          .get();
      return snapshot.docs
          .map((doc) => HudlPlay.fromFirestore(doc))
          .toList();
    } catch (e) {
      return DemoData.hudlPlays
          .where((p) => p.filmId == filmId)
          .toList();
    }
  }

  /// Get all player stats for a film.
  Future<List<HudlPlayerStats>> getFilmPlayerStats(String filmId) async {
    try {
      final snapshot = await _db
          .collection('hudlPlayerStats')
          .where('filmId', isEqualTo: filmId)
          .get();
      return snapshot.docs
          .map((doc) => HudlPlayerStats.fromFirestore(doc))
          .toList();
    } catch (e) {
      return DemoData.hudlPlayerStats
          .where((s) => s.filmId == filmId)
          .toList();
    }
  }

  /// Get a player's stats across all films.
  Future<List<HudlPlayerStats>> getPlayerFilmStats(String playerId) async {
    try {
      final snapshot = await _db
          .collection('hudlPlayerStats')
          .where('playerId', isEqualTo: playerId)
          .get();
      return snapshot.docs
          .map((doc) => HudlPlayerStats.fromFirestore(doc))
          .toList();
    } catch (e) {
      return DemoData.hudlPlayerStats
          .where((s) => s.playerId == playerId)
          .toList();
    }
  }

  /// Import a Hudl film (coach action).
  Future<String?> createHudlFilm(HudlFilm film) async {
    try {
      final docRef = await _db.collection('hudlFilms').add(film.toFirestore());
      return docRef.id;
    } catch (e) {
      return null;
    }
  }

  /// Save play breakdown for a film.
  Future<void> saveHudlPlays(String filmId, List<HudlPlay> plays) async {
    try {
      final batch = _db.batch();
      for (final play in plays) {
        final ref = _db
            .collection('hudlFilms')
            .doc(filmId)
            .collection('plays')
            .doc();
        batch.set(ref, play.toFirestore());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to save Hudl plays: $e');
    }
  }

  /// Save player stats for a film.
  Future<void> saveHudlPlayerStats(List<HudlPlayerStats> stats) async {
    try {
      final batch = _db.batch();
      for (final stat in stats) {
        final ref = _db.collection('hudlPlayerStats').doc();
        batch.set(ref, stat.toFirestore());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to save Hudl player stats: $e');
    }
  }
}