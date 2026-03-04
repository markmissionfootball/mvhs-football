import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/diablo_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/strength_provider.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';

class StrengthHubScreen extends ConsumerWidget {
  const StrengthHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider);

    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'STRENGTH',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Workout
            const SectionHeader(title: "TODAY'S WORKOUT"),
            _WorkoutSection(),
            const SizedBox(height: 24),

            // My Maxes
            const SectionHeader(title: 'MY MAXES'),
            _MaxesSection(playerId: currentUid),
            const SizedBox(height: 24),

            // View Max History button
            Center(
              child: OutlinedButton(
                onPressed: () => context.push('/profile/strength/maxes'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'VIEW MAX HISTORY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _WorkoutSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(currentWorkoutProvider);

    return workoutAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: DiabloColors.gold),
        ),
      ),
      error: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DiabloColors.darkCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Could not load workout',
          style: TextStyle(color: Colors.white54),
        ),
      ),
      data: (workout) {
        if (workout == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DiabloColors.darkCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No workout assigned today',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        final exercises = workout.exercises;
        final showCount = exercises.length > 4 ? 4 : exercises.length;
        final remaining = exercises.length - showCount;

        return Container(
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
                  const Icon(
                    Icons.fitness_center,
                    color: DiabloColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    workout.phaseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...exercises.take(showCount).map(
                    (exercise) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '${exercise.sets}x${exercise.reps}',
                            style: const TextStyle(
                              color: DiabloColors.gold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              if (remaining > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ $remaining more',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MaxesSection extends ConsumerWidget {
  final String playerId;
  const _MaxesSection({required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxesAsync = ref.watch(maxEntriesProvider(playerId));

    return maxesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: DiabloColors.gold),
        ),
      ),
      error: (_, __) => const Text(
        'Could not load maxes',
        style: TextStyle(color: Colors.white54),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Text(
            'No max entries recorded yet',
            style: TextStyle(color: Colors.white54),
          );
        }

        final latest = entries.first;
        final lifts = <MapEntry<String, double?>>[];
        if (latest.clean != null) lifts.add(MapEntry('Clean', latest.clean));
        if (latest.squat != null) lifts.add(MapEntry('Squat', latest.squat));
        if (latest.bench != null) lifts.add(MapEntry('Bench', latest.bench));
        if (latest.incline != null) {
          lifts.add(MapEntry('Incline', latest.incline));
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: lifts
              .map(
                (lift) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2,
                  child: StatCard(
                    value: '${lift.value?.toInt() ?? 0}',
                    label: lift.key,
                    variant: StatCardVariant.gold,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
