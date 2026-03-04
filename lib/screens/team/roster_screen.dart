import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/diablo_colors.dart';
import '../../providers/players_provider.dart';
import '../../providers/coaches_provider.dart';
import '../../models/depth_chart.dart';
import '../../widgets/player_roster_tile.dart';
import '../../widgets/coach_tile.dart';
import '../../widgets/empty_state.dart';

class RosterScreen extends ConsumerWidget {
  const RosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: DiabloColors.darkBackground,
        appBar: AppBar(
          backgroundColor: DiabloColors.red,
          title: const Text(
            'TEAM',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: DiabloColors.gold,
            labelColor: DiabloColors.gold,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            tabs: [
              Tab(text: 'ROSTER'),
              Tab(text: 'DEPTH CHART'),
              Tab(text: 'COACHES'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _RosterTab(),
            _DepthChartTab(),
            _CoachesTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 1: Roster ───────────────────────────────────────────────────────────

class _RosterTab extends ConsumerWidget {
  const _RosterTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(rosterProvider('varsity'));

    return playersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DiabloColors.gold),
      ),
      error: (_, __) => const EmptyState(
        icon: Icons.people,
        title: 'NO PLAYERS',
      ),
      data: (players) {
        if (players.isEmpty) {
          return const EmptyState(
            icon: Icons.people,
            title: 'NO PLAYERS',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: players.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final player = players[index];
            return PlayerRosterTile(
              jerseyNumber: player.jerseyNumber,
              name: player.fullName,
              position: player.position,
              grade: player.grade,
            );
          },
        );
      },
    );
  }
}

// ─── Tab 2: Depth Chart ──────────────────────────────────────────────────────

class _DepthChartTab extends ConsumerStatefulWidget {
  const _DepthChartTab();

  @override
  ConsumerState<_DepthChartTab> createState() => _DepthChartTabState();
}

class _DepthChartTabState extends ConsumerState<_DepthChartTab> {
  String _selectedType = 'offense';

  @override
  Widget build(BuildContext context) {
    final depthChartAsync = ref.watch(depthChartsProvider(_selectedType));

    return Column(
      children: [
        // Toggle row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildChoiceChip('OFFENSE', 'offense'),
              const SizedBox(width: 8),
              _buildChoiceChip('DEFENSE', 'defense'),
            ],
          ),
        ),
        // Content
        Expanded(
          child: depthChartAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: DiabloColors.gold),
            ),
            error: (_, __) => const EmptyState(
              icon: Icons.assignment,
              title: 'NO DEPTH CHART',
            ),
            data: (depthCharts) {
              final allPositions = depthCharts
                  .expand((dc) => dc.positions)
                  .toList();

              if (allPositions.isEmpty) {
                return const EmptyState(
                  icon: Icons.assignment,
                  title: 'NO DEPTH CHART',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allPositions.length,
                itemBuilder: (context, index) =>
                    _buildPositionSection(allPositions[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label, String type) {
    final selected = _selectedType == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? DiabloColors.dark : Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      selected: selected,
      selectedColor: DiabloColors.gold,
      backgroundColor: DiabloColors.darkCard,
      side: BorderSide.none,
      onSelected: (_) {
        setState(() => _selectedType = type);
      },
    );
  }

  Widget _buildPositionSection(DepthChartPosition pos) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position name
          Text(
            pos.position.toUpperCase(),
            style: const TextStyle(
              color: DiabloColors.gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          // Starters
          for (final starter in pos.starters)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                starter.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          // Backups
          for (final backup in pos.backups)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 2),
              child: Text(
                backup.name,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Coaches ──────────────────────────────────────────────────────────

class _CoachesTab extends ConsumerWidget {
  const _CoachesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coachesAsync = ref.watch(coachesProvider);

    return coachesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DiabloColors.gold),
      ),
      error: (_, __) => const EmptyState(
        icon: Icons.school,
        title: 'NO COACHES',
      ),
      data: (coaches) {
        if (coaches.isEmpty) {
          return const EmptyState(
            icon: Icons.school,
            title: 'NO COACHES',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: coaches.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final coach = coaches[index];
            return CoachTile(
              name: coach.fullName,
              title: coach.title,
              positionGroup: coach.positionGroup,
              isHeadCoach: coach.title.contains('Head'),
            );
          },
        );
      },
    );
  }
}
