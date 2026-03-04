import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';
import '../theme/diablo_colors.dart';
import 'status_badge.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback? onTap;

  const GameCard({
    super.key,
    required this.game,
    this.onTap,
  });

  Color get _accentColor {
    if (!game.isPlayed) return DiabloColors.gold;
    return game.result!.win ? const Color(0xFF4CAF50) : DiabloColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DiabloColors.darkCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Week number in gold circle
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: DiabloColors.gold,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${game.week}',
                    style: const TextStyle(
                      color: DiabloColors.dark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Opponent name and date/time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      game.opponent.toUpperCase(),
                      style: const TextStyle(
                        color: DiabloColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat.MMMd().format(game.date)} ${game.time}'.trim(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right side: score or home/away badge
              if (game.isPlayed) _buildScoreSection() else _buildUpcomingBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
    final result = game.result!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'MV ${result.mvScore} - OPP ${result.oppScore}',
          style: const TextStyle(
            color: DiabloColors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        result.win ? const StatusBadge.win() : const StatusBadge.loss(),
      ],
    );
  }

  Widget _buildUpcomingBadge() {
    return game.isHome ? const StatusBadge.home() : const StatusBadge.away();
  }
}
