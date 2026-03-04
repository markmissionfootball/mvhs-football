import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/hudl_film.dart';
import '../../providers/hudl_provider.dart';
import '../../theme/diablo_colors.dart';
import '../../widgets/diamond_divider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';

class FilmRoomScreen extends ConsumerWidget {
  const FilmRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filmsAsync = ref.watch(myFilmsProvider);
    final statsAsync = ref.watch(myFilmStatsProvider);

    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'FILM ROOM',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: filmsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DiabloColors.gold),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'COULD NOT LOAD FILM',
          subtitle: error.toString(),
        ),
        data: (films) {
          return statsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: DiabloColors.gold),
            ),
            error: (error, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'COULD NOT LOAD STATS',
              subtitle: error.toString(),
            ),
            data: (stats) {
              if (films.isEmpty) {
                return const EmptyState(
                  icon: Icons.videocam_off,
                  title: 'NO FILM AVAILABLE',
                  subtitle: 'Game film will appear here once reviewed',
                );
              }

              return _FilmRoomBody(films: films, stats: stats);
            },
          );
        },
      ),
    );
  }
}

class _FilmRoomBody extends StatelessWidget {
  final List<HudlFilm> films;
  final List<HudlPlayerStats> stats;

  const _FilmRoomBody({required this.films, required this.stats});

  double get _averageGrade {
    final graded = stats.where((s) => s.overallGrade != null).toList();
    if (graded.isEmpty) return 0;
    return graded.map((s) => s.overallGrade!).reduce((a, b) => a + b) /
        graded.length;
  }

  int get _gamesReviewed => stats.where((s) => s.overallGrade != null).length;

  double? get _trend {
    final graded = stats.where((s) => s.overallGrade != null).toList();
    if (graded.length < 2) return null;
    return graded.last.overallGrade! - graded[graded.length - 2].overallGrade!;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Season Overview Section
        const SectionHeader(title: 'SEASON OVERVIEW'),
        _buildSeasonOverview(),
        const SizedBox(height: 24),

        // Game-by-Game Section
        const SectionHeader(title: 'GAME-BY-GAME'),
        ...films.map((film) => _GameFilmCard(
              film: film,
              playerStats: stats.where((s) => s.filmId == film.id).toList(),
            )),
      ],
    );
  }

  Widget _buildSeasonOverview() {
    final avg = _averageGrade;
    final trendVal = _trend;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DiabloColors.darkCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _GradeCircle(grade: avg, size: 64, fontSize: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _gradeLabel(avg),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AVG GRADE ACROSS $_gamesReviewed GAMES',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (trendVal != null) ...[
            Icon(
              trendVal >= 0 ? Icons.trending_up : Icons.trending_down,
              color: trendVal >= 0 ? Colors.green : DiabloColors.red,
              size: 28,
            ),
            const SizedBox(width: 4),
            Text(
              '${trendVal >= 0 ? "+" : ""}${trendVal.toStringAsFixed(1)}',
              style: TextStyle(
                color: trendVal >= 0 ? Colors.green : DiabloColors.red,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GameFilmCard extends StatefulWidget {
  final HudlFilm film;
  final List<HudlPlayerStats> playerStats;

  const _GameFilmCard({required this.film, required this.playerStats});

  @override
  State<_GameFilmCard> createState() => _GameFilmCardState();
}

class _GameFilmCardState extends State<_GameFilmCard> {
  bool _expanded = false;

  HudlPlayerStats? get _stats =>
      widget.playerStats.isNotEmpty ? widget.playerStats.first : null;

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final grade = stats?.overallGrade ?? 0;
    final dateStr = DateFormat('MMM d, yyyy').format(widget.film.gameDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DiabloColors.darkCard,
            borderRadius: BorderRadius.circular(8),
            border: _expanded
                ? Border.all(color: DiabloColors.gold.withValues(alpha: 0.4))
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  _GradeCircle(grade: grade, size: 44, fontSize: 15),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'vs ${widget.film.opponent}'.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (stats != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _gradeColor(grade).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (stats.gradeLabel ?? _gradeLabel(grade)).toUpperCase(),
                        style: TextStyle(
                          color: _gradeColor(grade),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),

              // Key Stats Line
              if (stats != null && stats.stats.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _buildStatsLine(stats.stats),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],

              // Expanded Detail
              if (_expanded && stats != null) ...[
                const SizedBox(height: 12),
                const DiamondDivider(
                  color: Colors.white24,
                  lineWidth: 40,
                  diamondSize: 10,
                ),
                const SizedBox(height: 12),

                // Strengths
                if (stats.strengths.isNotEmpty) ...[
                  _buildDetailSection(
                    'STRENGTHS',
                    Icons.check_circle_outline,
                    Colors.green,
                    stats.strengths,
                  ),
                  const SizedBox(height: 12),
                ],

                // Areas to Improve
                if (stats.areasToImprove.isNotEmpty) ...[
                  _buildDetailSection(
                    'AREAS TO IMPROVE',
                    Icons.flag_outlined,
                    DiabloColors.gold,
                    stats.areasToImprove,
                  ),
                  const SizedBox(height: 12),
                ],

                // AI Analysis
                if (stats.aiAnalysis != null &&
                    stats.aiAnalysis!.isNotEmpty) ...[
                  const Text(
                    'AI ANALYSIS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stats.aiAnalysis!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Highlight Plays
                if (stats.highlightPlays.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.star_outline,
                        color: DiabloColors.gold,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${stats.highlightPlays.length} HIGHLIGHT PLAYS',
                        style: const TextStyle(
                          color: DiabloColors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildStatsLine(Map<String, dynamic> stats) {
    final parts = <String>[];
    if (stats.containsKey('completions') && stats.containsKey('attempts')) {
      parts.add('${stats["completions"]}/${stats["attempts"]}');
    }
    if (stats.containsKey('yards')) {
      parts.add('${stats["yards"]} YDS');
    }
    if (stats.containsKey('touchdowns')) {
      parts.add('${stats["touchdowns"]} TD');
    }
    if (stats.containsKey('tackles')) {
      parts.add('${stats["tackles"]} TKL');
    }
    if (stats.containsKey('interceptions')) {
      parts.add('${stats["interceptions"]} INT');
    }
    if (stats.containsKey('receptions')) {
      parts.add('${stats["receptions"]} REC');
    }
    if (stats.containsKey('rushYards')) {
      parts.add('${stats["rushYards"]} RUSH');
    }
    if (parts.isEmpty) return 'No stats available';
    return parts.join('  \u2022  ');
  }
}

// Grade Circle Widget

class _GradeCircle extends StatelessWidget {
  final double grade;
  final double size;
  final double fontSize;

  const _GradeCircle({
    required this.grade,
    required this.size,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _gradeColor(grade).withValues(alpha: 0.15),
        border: Border.all(
          color: _gradeColor(grade),
          width: 2.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        grade.round().toString(),
        style: TextStyle(
          color: _gradeColor(grade),
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Helper Functions

Color _gradeColor(double grade) {
  if (grade >= 80) return Colors.green;
  if (grade >= 60) return DiabloColors.gold;
  return DiabloColors.red;
}

String _gradeLabel(double grade) {
  if (grade >= 90) return 'Elite';
  if (grade >= 80) return 'Above Average';
  if (grade >= 70) return 'Average';
  if (grade >= 60) return 'Below Average';
  return 'Needs Improvement';
}
