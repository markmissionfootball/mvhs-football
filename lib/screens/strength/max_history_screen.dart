import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../theme/diablo_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/strength_provider.dart';
import '../../models/max_entry.dart';

class MaxHistoryScreen extends ConsumerWidget {
  const MaxHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(currentUidProvider);
    final maxesAsync = ref.watch(maxEntriesProvider(currentUid));

    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'MAX HISTORY',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: maxesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DiabloColors.gold),
        ),
        error: (_, __) => const Center(
          child: Text(
            'Could not load max history',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text(
                'No max entries recorded yet',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            );
          }

          // Sort entries by date ascending for chart
          final sorted = List<MaxEntry>.from(entries)
            ..sort((a, b) => a.date.compareTo(b.date));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _LiftChart(title: 'CLEAN', entries: sorted, getValue: (e) => e.clean),
                const SizedBox(height: 16),
                _LiftChart(title: 'SQUAT', entries: sorted, getValue: (e) => e.squat),
                const SizedBox(height: 16),
                _LiftChart(title: 'BENCH', entries: sorted, getValue: (e) => e.bench),
                const SizedBox(height: 16),
                _LiftChart(title: 'INCLINE', entries: sorted, getValue: (e) => e.incline),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LiftChart extends StatelessWidget {
  final String title;
  final List<MaxEntry> entries;
  final double? Function(MaxEntry) getValue;

  const _LiftChart({
    required this.title,
    required this.entries,
    required this.getValue,
  });

  @override
  Widget build(BuildContext context) {
    // Filter entries that have data for this lift
    final dataPoints = <MapEntry<DateTime, double>>[];
    for (final entry in entries) {
      final val = getValue(entry);
      if (val != null) {
        dataPoints.add(MapEntry(entry.date, val));
      }
    }

    if (dataPoints.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DiabloColors.darkCard,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'No data recorded',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('M/d');
    final minY = dataPoints.map((e) => e.value).reduce((a, b) => a < b ? a : b) - 10;
    final maxY = dataPoints.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 10;

    final spots = dataPoints.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DiabloColors.darkCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white12,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dataPoints.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          dateFormat.format(dataPoints[idx].key),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: DiabloColors.gold,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: DiabloColors.gold,
                          strokeWidth: 2,
                          strokeColor: DiabloColors.darkCard,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: DiabloColors.gold.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
