import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_hub_screen.dart';
import '../screens/admin/invite_user_screen.dart';
import '../screens/admin/post_announcement_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/sms_verify_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/auth/passkey_register_screen.dart';
import '../screens/auth/onboarding_survey_screen.dart';
import '../screens/calendar/calendar_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_room_screen.dart';
import '../screens/chat/new_chat_screen.dart';
import '../screens/chat/group_info_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/more/awards_screen.dart';
import '../screens/more/settings_screen.dart';
import '../screens/profile/player_profile_screen.dart';
import '../screens/recruiting/add_college_screen.dart';
import '../screens/recruiting/recruiting_hub_screen.dart';
import '../screens/schedule/schedule_screen.dart';
import '../screens/agent/agent_chat_screen.dart';
import '../screens/stats/stats_overview_screen.dart';
import '../screens/strength/max_history_screen.dart';
import '../screens/strength/strength_hub_screen.dart';
import '../screens/team/roster_screen.dart';
import '../screens/history/program_history_screen.dart';
import '../screens/film/film_room_screen.dart';
import '../screens/film/hudl_import_screen.dart';
import '../widgets/shell_scaffold.dart';

// ── GoRouter refresh helper ────────────────────────────────────────

/// Converts a [Stream] into a [ChangeNotifier] so GoRouter can
/// listen for auth-state changes and re-evaluate redirects.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ── Navigator keys ─────────────────────────────────────────────────

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

// ── Auth routes that don't require login ───────────────────────────

const _publicPaths = {
  '/login',
  '/forgot-password',
  '/register',
};

// ── Router Provider ────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  // ignore: deprecated_member_use
  final authStream = ref.watch(firebaseAuthProvider.stream);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: _GoRouterRefreshStream(authStream),
    redirect: (context, state) {
      final isDemoMode = ref.read(isDemoModeProvider);
      if (isDemoMode) return null; // Skip all guards in demo mode

      final authState = ref.read(firebaseAuthProvider);
      final isLoggedIn =
          authState.whenOrNull(data: (user) => user != null) ?? false;
      final path = state.uri.path;
      final isPublicRoute = _publicPaths.contains(path);

      // Not logged in → must be on a public route
      if (!isLoggedIn && !isPublicRoute) return '/login';

      // Logged in → don't show login page, route to appropriate screen
      if (isLoggedIn && path == '/login') {
        final appUser =
            ref.read(appUserProvider).whenOrNull(data: (u) => u);
        if (appUser == null) return '/home';
        if (appUser.mustChangePassword) return '/change-password';
        if (!appUser.onboardingSurveyComplete) return '/onboarding';
        return '/home';
      }

      return null; // No redirect needed
    },
    routes: [
      // ── Auth routes (outside shell) ──────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/sms-verify',
        builder: (context, state) => const SmsVerifyScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/passkey-register',
        builder: (context, state) => const PasskeyRegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingSurveyScreen(),
      ),

      // ── Main app shell with bottom nav ───────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScheduleScreen(),
            ),
          ),
          GoRoute(
            path: '/coach',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AgentChatScreen(),
            ),
          ),
          GoRoute(
            path: '/team',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RosterScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PlayerProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/profile/chat',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChatListScreen(),
            ),
          ),
        ],
      ),

      // ── Chat routes (outside shell — covers bottom nav) ──────
      GoRoute(
        path: '/chat/new',
        builder: (context, state) => const NewChatScreen(),
      ),
      GoRoute(
        path: '/chat/:roomId/info',
        builder: (context, state) => GroupInfoScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),
      GoRoute(
        path: '/chat/:roomId',
        builder: (context, state) => ChatRoomScreen(
          roomId: state.pathParameters['roomId']!,
        ),
      ),

      // ── Profile sub-screens (full-screen) ────────────────────
      GoRoute(
        path: '/profile/strength/maxes',
        builder: (context, state) => const MaxHistoryScreen(),
      ),
      GoRoute(
        path: '/profile/strength',
        builder: (context, state) => const StrengthHubScreen(),
      ),
      GoRoute(
        path: '/profile/stats',
        builder: (context, state) => const StatsOverviewScreen(),
      ),
      GoRoute(
        path: '/profile/recruiting/add',
        builder: (context, state) => const AddCollegeScreen(),
      ),
      GoRoute(
        path: '/profile/recruiting',
        builder: (context, state) => const RecruitingHubScreen(),
      ),
      GoRoute(
        path: '/profile/awards',
        builder: (context, state) => const AwardsScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Film Room (Hudl) ──────────────────────────────────────
      GoRoute(
        path: '/profile/film',
        builder: (context, state) => const FilmRoomScreen(),
      ),
      GoRoute(
        path: '/admin/import-film',
        builder: (context, state) => const HudlImportScreen(),
      ),

      // ── Program History ──────────────────────────────────────
      GoRoute(
        path: '/history',
        builder: (context, state) => const ProgramHistoryScreen(),
      ),

      // ── Calendar ─────────────────────────────────────────────
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),

      // ── Admin ────────────────────────────────────────────────
      GoRoute(
        path: '/admin/announcement',
        builder: (context, state) => const PostAnnouncementScreen(),
      ),
      GoRoute(
        path: '/admin/invite',
        builder: (context, state) => const InviteUserScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHubScreen(),
      ),
    ],
  );
});
