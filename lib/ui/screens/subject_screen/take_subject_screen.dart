import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// หน้าลงทะเบียนรายวิชา
class TakeSubjectScreen extends StatefulWidget {
  const TakeSubjectScreen({super.key});

  @override
  State<TakeSubjectScreen> createState() => _TakeSubjectScreenState();
}

class _TakeSubjectScreenState extends State<TakeSubjectScreen> {
  /// เก็บ `id` ของคอร์สที่ผู้ใช้กด "ดูตารางเวลา"
  final Set<int> _expandedCourseIds = {};

  @override
  void initState() {
    super.initState();

    /// โหลดรายการคอร์สทั้งหมดทันทีที่เข้าหน้านี้
    Provider.of<SubjectProvider>(context, listen: false).fetchCoursesFromApi();
  }

  /// สลับสถานะการแสดงตารางเวลา (Expand/Collapse)
  Future<void> _toggleSchedule(SubjectProvider provider, int courseId) async {
    final isExpanded = _expandedCourseIds.contains(courseId);

    // ถ้าคลิกซ้ำให้ปิดการแสดงผล
    if (isExpanded) {
      setState(() => _expandedCourseIds.remove(courseId));
      return;
    }

    // ถ้ายังไม่เคยเปิดให้แสดงตารางเวลา
    setState(() => _expandedCourseIds.add(courseId));

    // โหลดข้อมูลตารางเวลาเฉพาะคอร์สที่ยังไม่ได้โหลด
    if (!provider.isScheduleLoaded(courseId)) {
      try {
        await provider.fetchCourseSchedules(courseId);
      } catch (e) {
        if (!mounted) return;

        // แจ้ง Error กรณีโหลดไม่สำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดตารางเวลาได้: $e'),
            backgroundColor: Colors.red,
          ),
        );

        setState(() => _expandedCourseIds.remove(courseId));
      }
    }
  }

  /// แปลชื่อวันจากภาษาอังกฤษ → ภาษาไทย
  String _translateDay(String day) {
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
    final provider = Provider.of<SubjectProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียนรายวิชา'),
        backgroundColor: const Color(0xFF113F67),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      /// ถ้าไม่มีคอร์ส → แสดง Loading, ถ้ามีแล้ว → แสดง List
      body:
          provider.courses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: provider.courses.length,
                itemBuilder: (context, index) {
                  final course = provider.courses[index];
                  final isRegistered = provider.isCourseRegistered(course.id);
                  final isExpanded = _expandedCourseIds.contains(course.id);
                  final schedules = provider.getCourseSchedules(course.id);
                  final isScheduleLoading = provider.isScheduleLoading(
                    course.id,
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// --- ส่วนข้อมูลคอร์ส + ปุ่มลงทะเบียน ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// ข้อมูลคอร์ส
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ชื่อคอร์ส
                                    Text(
                                      '${course.courseName} (${course.courseCode})',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // หน่วยกิต
                                    Text(
                                      'หน่วยกิต: ${course.credits}',
                                      style: TextStyle(fontSize: 13.sp),
                                    ),
                                    const SizedBox(height: 4),

                                    // สถานะ (เปิดรับ/เต็มแล้ว)
                                    Text(
                                      course.availabilityText,
                                      style: TextStyle(fontSize: 13.sp),
                                    ),
                                    const SizedBox(height: 4),

                                    // คำอธิบายวิชา (ถ้ามี)
                                    if (course.description.isNotEmpty)
                                      Text(
                                        course.description,
                                        style: TextStyle(fontSize: 13.sp),
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              /// ปุ่ม "ลงทะเบียน"
                              ElevatedButton(
                                onPressed:
                                    isRegistered || !course.isAvailable
                                        ? null
                                        : () async {
                                          try {
                                            // เปิด Dialog Loading
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder:
                                                  (_) => const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                            );

                                            // เรียก API ลงทะเบียน
                                            await provider.registerCourse(
                                              course.id,
                                            );

                                            if (mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'ลงทะเบียน ${course.courseName} สำเร็จ',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'ลงทะเบียนไม่สำเร็จ: $e',
                                                  ),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isRegistered
                                          ? Colors.grey
                                          : (!course.isAvailable
                                              ? Colors.red
                                              : const Color(0xFF113F67)),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(
                                  isRegistered
                                      ? 'ลงทะเบียนแล้ว'
                                      : (!course.isAvailable
                                          ? 'เต็มแล้ว'
                                          : 'ลงทะเบียน'),
                                  style: TextStyle(fontSize: 12.sp),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          /// --- ปุ่มกดแสดง/ซ่อนตารางเวลา ---
                          TextButton.icon(
                            onPressed:
                                () => _toggleSchedule(provider, course.id),
                            icon: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                            label: Text(
                              isExpanded ? 'ซ่อนตารางเวลา' : 'ดูตารางเวลา',
                            ),
                          ),

                          /// --- ตารางเวลา ---
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child:
                                  isScheduleLoading
                                      ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                      : schedules.isEmpty
                                      ? const Text('ไม่มีข้อมูลตารางเวลา')
                                      : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children:
                                            schedules.map((s) {
                                              return Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.only(
                                                  top: 4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF5F9FF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            '${_translateDay(s.dayOfWeek)} ${s.formattedTimeRange}',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                      ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
