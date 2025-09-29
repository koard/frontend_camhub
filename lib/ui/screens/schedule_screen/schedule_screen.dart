import 'package:flutter/material.dart';
// Removed asset/mock usage; now only real service.
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campusapp/core/routes.dart';
import 'package:campusapp/ui/widgets/base/day_selector.dart';
import 'package:campusapp/ui/service/schedule_services.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> futureSchedule;
  String selectedDay = 'ทั้งหมด';

  final List<String> days = const [
    'ทั้งหมด',
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    futureSchedule = _fetchSchedules();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Persist latest resolved schedule when app goes background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistCurrentScheduleSnapshot();
    }
  }

  Future<void> _persistCurrentScheduleSnapshot() async {
    try {
      if (!mounted) return;
      // We attempt to capture current data from the future if already completed.
      // If not completed yet, skip.
      // Best effort: await with timeout small to avoid blocking.
      final data = await futureSchedule.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => <Map<String, dynamic>>[],
      );
      if (data.isNotEmpty) {
        await ScheduleCourseService().persistScheduleToFile(data);
      }
    } catch (_) {
      // ignore best-effort errors
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSchedules() async {
    final service = ScheduleCourseService();
    final list = await service.getScheduleWithFileFallback();
    // ป้องกันรูปแบบอื่น แปลงให้แน่ใจว่าเป็น Map<String,dynamic>
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _thaiDay(String eng) {
    switch (eng.toLowerCase()) {
      case 'monday':
        return 'จันทร์';
      case 'tuesday':
        return 'อังคาร';
      case 'wednesday':
        return 'พุธ';
      case 'thursday':
        return 'พฤหัสบดี';
      case 'friday':
        return 'ศุกร์';
      case 'saturday':
        return 'เสาร์';
      case 'sunday':
        return 'อาทิตย์';
      default:
        return eng;
    }
  }

  bool _matchDayFilter(Map<String, dynamic> item) {
    if (selectedDay == 'ทั้งหมด') return true;
    final apiDay = item['day_of_week']?.toString() ?? '';
    return _thaiDay(apiDay) == selectedDay;
  }

  String _formatTime(String t) {
    if (t.isEmpty) return t;
    // ตัดวินาทีให้เหลือ HH:MM
    if (t.contains(':')) {
      final parts = t.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ตารางเรียน'),
        backgroundColor: const Color(0xFF113F67),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.home);
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureSchedule = _fetchSchedules();
          });
          await futureSchedule;
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: futureSchedule,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(height: 120.h),
                  Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}')),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: 120.h),
                  const Center(child: Text("ไม่พบข้อมูลตารางเรียนออนไลน์ ")),
                ],
              );
            }

            final scheduleList = snapshot.data!;
            final filteredList = scheduleList.where(_matchDayFilter).toList();

            return Column(
              children: [
                DaySelector(
                  selectedDay: selectedDay,
                  days: days,
                  onChanged: (value) {
                    setState(() {
                      selectedDay = value;
                    });
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        // --- Extract course name safely ---
                        String courseName = 'ชื่อวิชาไม่ระบุ';
                        final rawCourse = item['course'];
                        if (rawCourse is Map<String, dynamic>) {
                          final c = rawCourse;
                          final nameCandidate = c['course_name'] ?? c['name'];
                          if (nameCandidate != null &&
                              nameCandidate.toString().trim().isNotEmpty) {
                            courseName = nameCandidate.toString();
                          }
                        } else if (rawCourse is String &&
                            rawCourse.trim().isNotEmpty) {
                          courseName = rawCourse.trim();
                        }
                        final dynamic roomRaw = item['room'];
                        Map<String, dynamic>? room;
                        Map<String, dynamic>? location;
                        String roomName = '-';
                        if (roomRaw is Map<String, dynamic>) {
                          room = roomRaw;
                          roomName = room['name']?.toString() ?? '-';
                          final locRaw = room['location'];
                          if (locRaw is Map<String, dynamic>) {
                            location = locRaw;
                          }
                        } else if (roomRaw is String) {
                          roomName = roomRaw;
                        }
                        final dayThai = _thaiDay(
                          item['day_of_week']?.toString() ?? '',
                        );
                        final start = _formatTime(
                          item['start_time']?.toString() ?? '',
                        );
                        final end = _formatTime(
                          item['end_time']?.toString() ?? '',
                        );
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 8.h),
                          child: Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 18.sp,
                                      color: const Color(0xFF113F67),
                                    ),
                                    SizedBox(width: 8.w),
                                    // ใช้ Expanded + ellipsis ป้องกัน overflow
                                    Expanded(
                                      child: Tooltip(
                                        message: courseName,
                                        preferBelow: false,
                                        child: Text(
                                          courseName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text('วัน: $dayThai'),
                                Text('เวลา: $start - $end'),
                                Text('ห้อง: $roomName'),
                                if (location != null)
                                  Text(
                                    'อาคาร: ${location['name']} (${location['code']})',
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
