import 'package:flutter/material.dart';
import 'package:campusapp/core/routes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/events_provider.dart';
import '../../widgets/event_card.dart';
import '../../widgets/date_range_selector.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventsProvider _eventsProvider = EventsProvider();
  late Future<List<Map<String, dynamic>>> futureEvents;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    futureEvents = _eventsProvider.fetchEvents();
  }

  Future<void> _selectDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange:
          selectedDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now.add(const Duration(days: 7)),
          ),
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureEvents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('กิจกรรม'),
              backgroundColor: const Color(0xFF113F67),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
              ),
            ),
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'คุณออฟไลน์อยู่',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'ไม่สามารถเชื่อมต่อเครือข่ายได้ในขณะนี้\nกรุณาตรวจสอบการเชื่อมต่อแล้วลองใหม่',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          futureEvents = _eventsProvider.fetchEvents();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('กิจกรรม'),
              backgroundColor: const Color(0xFF113F67),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
              ),
            ),
            body: const Center(child: Text("ไม่พบข้อมูลกิจกรรม")),
          );
        }

        List<Map<String, dynamic>> events = snapshot.data!;

        // Filter events by date range if selected
        if (selectedDateRange != null) {
          events =
              events.where((event) {
                final start = DateTime.tryParse(event["start_date"] ?? '');
                final end = DateTime.tryParse(event["end_date"] ?? '');
                if (start == null || end == null) return false;
                return start.isBefore(
                      selectedDateRange!.end.add(const Duration(days: 1)),
                    ) &&
                    end.isAfter(
                      selectedDateRange!.start.subtract(
                        const Duration(days: 1),
                      ),
                    );
              }).toList();
        }

        // Sort events: newest first by start_date (fallback to end_date)
        events.sort((a, b) {
          DateTime? aStart = DateTime.tryParse(a['start_date'] ?? '');
          DateTime? bStart = DateTime.tryParse(b['start_date'] ?? '');
          DateTime? aEnd = DateTime.tryParse(a['end_date'] ?? '');
          DateTime? bEnd = DateTime.tryParse(b['end_date'] ?? '');

          final aDate = aStart ?? aEnd ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = bStart ?? bEnd ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate); // descending
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('กิจกรรม'),
            backgroundColor: const Color(0xFF113F67),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
            ),
          ),
          body: Column(
            children: [
              // Date Range Selector
              DateRangeSelector(
                selectedDateRange: selectedDateRange,
                onSelectDateRange: _selectDateRange,
                onClearDateRange: () {
                  setState(() {
                    selectedDateRange = null;
                  });
                },
              ),
              // Events Grid
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: GridView.builder(
                    itemCount: events.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8.h,
                      crossAxisSpacing: 8.w,
                      // Increase height for cards to prevent overflow
                      childAspectRatio: 3 / 5.3,
                    ),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return EventCard(event: event);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
