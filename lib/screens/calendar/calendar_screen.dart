import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/diablo_colors.dart';
import '../../providers/calendar_provider.dart';
import '../../models/calendar_event.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDay = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _selectedDay = null;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<CalendarEvent> _eventsForDay(DateTime day, List<CalendarEvent> allEvents) {
    return allEvents.where((e) => _isSameDay(e.date, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      backgroundColor: DiabloColors.darkBackground,
      appBar: AppBar(
        backgroundColor: DiabloColors.red,
        title: const Text(
          'CALENDAR',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: eventsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: DiabloColors.gold),
        ),
        error: (_, __) => const Center(
          child: Text(
            'Could not load calendar',
            style: TextStyle(color: Colors.white54),
          ),
        ),
        data: (events) => _buildCalendar(events),
      ),
    );
  }

  Widget _buildCalendar(List<CalendarEvent> events) {
    final monthFormat = DateFormat('MMMM yyyy');
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday % 7;

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: _previousMonth,
              ),
              Text(
                monthFormat.format(_selectedMonth).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: DiabloColors.gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildGrid(daysInMonth, firstWeekday, events),
        ),
        const SizedBox(height: 16),

        // Events for selected day
        if (_selectedDay != null)
          Expanded(child: _buildEventsList(_eventsForDay(_selectedDay!, events)))
        else
          const Expanded(
            child: Center(
              child: Text(
                'Select a day to see events',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrid(int daysInMonth, int firstWeekday, List<CalendarEvent> events) {
    final cells = <Widget>[];

    // Empty cells before the first day
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final dayEvents = _eventsForDay(date, events);
      final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);
      final hasGameEvent = dayEvents.any((e) => e.phase.toLowerCase().contains('game'));

      cells.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDay = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? DiabloColors.gold : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? DiabloColors.darkBackground : Colors.white,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (dayEvents.isNotEmpty)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? DiabloColors.darkBackground
                          : (hasGameEvent ? DiabloColors.red : DiabloColors.gold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: cells,
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'No events',
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DiabloColors.darkCard,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (event.timeRange != null)
                Text(
                  event.timeRange!,
                  style: const TextStyle(
                    color: DiabloColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (event.timeRange != null) const SizedBox(height: 4),
              Text(
                event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  event.description!,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
