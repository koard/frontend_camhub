import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/subject_provider.dart';
import 'take_subject_screen.dart';
import 'edit_subject_screen.dart'; // 👈 เพิ่ม import
import '../../../models/course_schedule.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  // Track expanded enrollments for showing schedules
  final Set<int> _expandedEnrollmentIds = {};
  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลการลงทะเบียนเมื่อเข้าหน้านี้
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);

    // Always fetch fresh data - no cache
    await provider.fetchCoursesFromApi();
    await provider.fetchEnrollments();
  }

  String _translateEnroll(String status) {
    switch (status) {
      case 'enrolled':
        return 'ลงทะเบียนแล้ว';
      default:
        return status; // คืนค่าเดิมถ้าไม่ตรงกับกรณีใดๆ
    }
  }

  Future<void> _navigateToTakeSubject() async {
    // ไปหน้าลงทะเบียนและรอผลลัพธ์
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TakeSubjectScreen()),
    );
    // เมื่อกลับมา ให้รีเฟรชข้อมูล
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);

    // รายวิชาที่ลงทะเบียนแล้วจาก API
    final registeredEnrollments =
        provider.enrollments
            .where((enrollment) => enrollment.status == 'enrolled')
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('วิชาที่ลงทะเบียนแล้ว'),
        backgroundColor: const Color(0xFF113F67),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const EditRegisteredSubjectScreen(), // 👈 หน้าสำหรับแก้ไข
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('แก้ไข'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToTakeSubject,
                    icon: const Icon(Icons.add),
                    label: const Text('ลงทะเบียนวิชา'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child:
                  registeredEnrollments.isEmpty
                      ? ListView(
                        children: const [
                          SizedBox(height: 200),
                          Center(child: Text('ยังไม่มีการลงทะเบียนวิชา')),
                        ],
                      )
                      : ListView.builder(
                        itemCount: registeredEnrollments.length,
                        itemBuilder: (context, index) {
                          final enrollment = registeredEnrollments[index];

                          final isExpanded = _expandedEnrollmentIds.contains(
                            enrollment.id,
                          );

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: const Color(
                                          0xFF113F67,
                                        ),
                                        child: const Icon(
                                          Icons.book,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              enrollment.courseName,
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'รหัสวิชา: ${enrollment.courseCode ?? '-'}',
                                              style: TextStyle(fontSize: 14.sp),
                                            ),
                                            Text(
                                              'สถานะ: ${_translateEnroll(enrollment.status)}',
                                              style: TextStyle(fontSize: 14.sp),
                                            ),
                                            Text(
                                              'วันที่ลงทะเบียน: ${enrollment.formattedEnrollmentDate}',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        enrollment.status == 'enrolled'
                                            ? Icons.check_circle
                                            : Icons.pending,
                                        color:
                                            enrollment.status == 'enrolled'
                                                ? Colors.green
                                                : Colors.orange,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Schedules dropdown toggle (visible if schedules exist)
                                  if (enrollment.hasSchedules)
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            if (isExpanded) {
                                              _expandedEnrollmentIds.remove(
                                                enrollment.id,
                                              );
                                            } else {
                                              _expandedEnrollmentIds.add(
                                                enrollment.id,
                                              );
                                            }
                                          });
                                        },
                                        icon: Icon(
                                          isExpanded
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                        ),
                                        label: Text(
                                          isExpanded
                                              ? 'ซ่อนตารางเวลา'
                                              : 'ดูตารางเวลา',
                                        ),
                                      ),
                                    ),
                                  // Expanded schedule list
                                  if (enrollment.hasSchedules && isExpanded)
                                    _ScheduleList(
                                      schedules: enrollment.schedules,
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
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  final List<CourseSchedule> schedules;

  const _ScheduleList({required this.schedules});

  String _thaiDay(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'วันจันทร์';
      case 'tuesday':
        return 'วันอังคาร';
      case 'wednesday':
        return 'วันพุธ';
      case 'thursday':
        return 'วันพฤหัสบดี';
      case 'friday':
        return 'วันศุกร์';
      case 'saturday':
        return 'วันเสาร์';
      case 'sunday':
        return 'วันอาทิตย์';
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children:
          schedules.map((s) {
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 18,
                    color: Color(0xFF113F67),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_thaiDay(s.dayOfWeek)} ${s.formattedTimeRange}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.roomName != null && s.roomName!.isNotEmpty
                              ? 'ห้อง: ${s.roomName}'
                              : 'ห้อง ID: ${s.roomId}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
