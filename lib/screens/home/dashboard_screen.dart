import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/announcements_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/strength_provider.dart';
import '../../theme/diablo_colors.dart';
import '../../widgets/diablo_app_bar.dart';
import '../../widgets/diamond_divider.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider(null));
    final workoutAsync = ref.watch(currentWorkoutProvider);
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: const DiabloAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: const BoxDecoration(
                color: DiabloColors.dark,
              ),
              child: Column(
                children: [
                  const Text(
                    'MISSION DRIVEN',
                    style: TextStyle(
                      color: DiabloColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const DiamondDivider(color: Colors.white54),
                  const SizedBox(height: 16),
                  Text(
                    'TRADITION NEVER\nGRADUATES',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2.0,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'OVER 50 YEARS OF EXCELLENCE',
                    style: TextStyle(
                      color: DiabloColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
            ),

            // Next Game card
            gamesAsync.when(
              data: (games) {
                final upcoming = games
                    .where((g) => g.result == null)
                    .toList()
                  ..sort((a, b) => a.date.compareTo(b.date));
                if (upcoming.isEmpty) return const SizedBox.shrink();
                final nextGame = upcoming.first;
                final dateStr =
                    DateFormat('EEE, MMM d').format(nextGame.date);
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DiabloColors.darkCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'NEXT GAME',
                              style: TextStyle(
                                color: DiabloColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const Spacer(),
                            nextGame.isHome
                                ? const StatusBadge.home()
                                : const StatusBadge.away(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nextGame.opponent,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '$dateStr \u2022 ${nextGame.time}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  StatCard(
                    value: '3x',
                    label: 'California State Champions',
                    variant: StatCardVariant.red,
                  ),
                  SizedBox(height: 12),
                  StatCard(
                    value: '26x',
                    label: 'South Coast League Champions',
                    variant: StatCardVariant.gold,
                  ),
                  SizedBox(height: 12),
                  StatCard(
                    value: '8x',
                    label: 'CIF Champions',
                    variant: StatCardVariant.red,
                  ),
                ],
              ),
            ),

            // Today's Workout card
            workoutAsync.when(
              data: (workout) {
                if (workout == null) return const SizedBox.shrink();
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onTap: () => context.push('/profile/strength'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DiabloColors.darkCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.fitness_center,
                                  color: DiabloColors.gold, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                "TODAY'S WORKOUT",
                                style: TextStyle(
                                  color: DiabloColors.gold,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            workout.phaseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${workout.exercises.length} exercises',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Quick Links
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickLink(Icons.list_alt, 'Roster'),
                  _buildQuickLink(Icons.calendar_today, 'Schedule'),
                  _buildQuickLink(Icons.groups, 'Coaches'),
                  _buildQuickLink(Icons.sports_football, 'Camps'),
                ],
              ),
            ),

            // Announcements section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'ANNOUNCEMENTS'),
                  announcementsAsync.when(
                    data: (announcements) {
                      if (announcements.isEmpty) {
                        return const Text(
                          'No announcements',
                          style: TextStyle(color: Colors.white54),
                        );
                      }
                      final display = announcements.take(3).toList();
                      return Column(
                        children: display.map((a) {
                          final timeAgo = _formatTimeAgo(a.createdAt);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: DiabloColors.darkCard,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    a.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    timeAgo,
                                    style: const TextStyle(
                                      color: DiabloColors.gold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: DiabloColors.gold,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    error: (_, __) => const Text(
                      'No announcements',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }

  Widget _buildQuickLink(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 36, color: DiabloColors.red),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
