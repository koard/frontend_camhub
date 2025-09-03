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
  int currentPage = 0;
  final int itemsPerPage = 6;
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
        currentPage = 0;
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
            body: Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text("ไม่พบข้อมูลกิจกรรม")),
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

        final totalPages = (events.length / itemsPerPage).ceil();
        final startIndex = currentPage * itemsPerPage;
        final endIndex = (startIndex + itemsPerPage).clamp(0, events.length);
        final pageEvents = events.sublist(startIndex, endIndex);

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
                    currentPage = 0;
                  });
                },
              ),
              // Events Grid
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: GridView.builder(
                    itemCount: pageEvents.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8.h,
                      crossAxisSpacing: 8.w,
                      childAspectRatio: 3 / 4.5,
                    ),
                    itemBuilder: (context, index) {
                      final event = pageEvents[index];
                      return EventCard(event: event);
                    },
                  ),
                ),
              ),
              // Pagination
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed:
                          currentPage > 0
                              ? () => setState(() => currentPage--)
                              : null,
                      child: Text(
                        "< ก่อนหน้า",
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      "หน้า ${currentPage + 1} / $totalPages",
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    SizedBox(width: 16.w),
                    ElevatedButton(
                      onPressed:
                          currentPage < totalPages - 1
                              ? () => setState(() => currentPage++)
                              : null,
                      child: Text("ถัดไป >", style: TextStyle(fontSize: 14.sp)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
