import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_event.dart';
import '../services/firestore_service.dart';

final calendarEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  return FirestoreService().getCalendarEvents();
});
