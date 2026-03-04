import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/diablo_colors.dart';
import '../../providers/games_provider.dart';
import '../../widgets/game_card.dart';
import '../../widgets/empty_state.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: DiabloColors.darkBackground,
        appBar: AppBar(
          backgroundColor: DiabloColors.red,
          title: const Text(
            'SCHEDULE',
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
              Tab(text: 'VARSITY'),
              Tab(text: 'JV'),
              Tab(text: 'FRESHMAN'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GameList(level: 'varsity'),
            _GameList(level: 'jv'),
            _GameList(level: 'freshman'),
          ],
        ),
      ),
    );
  }
}

class _GameList extends ConsumerWidget {
  final String level;

  const _GameList({required this.level});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamesAsync = ref.watch(gamesProvider(level));

    return gamesAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: DiabloColors.gold),
      ),
      error: (_, __) => const EmptyState(
        icon: Icons.calendar_today,
        title: 'NO GAMES SCHEDULED',
      ),
      data: (games) {
        if (games.isEmpty) {
          return const EmptyState(
            icon: Icons.calendar_today,
            title: 'NO GAMES SCHEDULED',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: games.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) => GameCard(game: games[index]),
        );
      },
    );
  }
}
