import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/diablo_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/recruiting_provider.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';

class RecruitingHubScreen extends ConsumerWidget {
  const RecruitingHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider);
    final profileAsync = ref.watch(recruitingProfileProvider(currentUid));

    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'RECRUITING',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DiabloColors.gold),
        ),
        error: (_, __) => const Center(
          child: Text(
            'Could not load recruiting profile',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.school,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SET UP YOUR RECRUITING PROFILE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Academics card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DiabloColors.darkCard,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _AcademicStat(
                        label: 'GPA',
                        value: profile.gpa?.toStringAsFixed(2) ?? '--',
                      ),
                      _AcademicStat(
                        label: 'SAT',
                        value: profile.satScore?.toString() ?? '--',
                      ),
                      _AcademicStat(
                        label: 'ACT',
                        value: profile.actScore?.toString() ?? '--',
                      ),
                      _AcademicStat(
                        label: 'NCAA ID',
                        value: profile.ncaaId ?? '--',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // College interests
                const SectionHeader(title: 'COLLEGE INTERESTS'),
                if (profile.collegeInterests.isEmpty)
                  const Text(
                    'No colleges added yet',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  )
                else
                  ...profile.collegeInterests.map(
                    (college) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DiabloColors.darkCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  college.school,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  college.status,
                                  style: const TextStyle(
                                    color: DiabloColors.gold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            label: college.level,
                            color: DiabloColors.gold,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Highlight videos
                const SectionHeader(title: 'HIGHLIGHT VIDEOS'),
                if (profile.highlightVideoUrls.isEmpty)
                  const Text(
                    'No highlight videos yet',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  )
                else
                  ...profile.highlightVideoUrls.map(
                    (url) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DiabloColors.darkCard,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.play_circle_fill,
                            color: DiabloColors.gold,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              url,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DiabloColors.gold,
        onPressed: () => context.push('/profile/recruiting/add'),
        child: const Icon(Icons.add, color: DiabloColors.darkBackground),
      ),
    );
  }
}

class _AcademicStat extends StatelessWidget {
  final String label;
  final String value;

  const _AcademicStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: DiabloColors.gold,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
