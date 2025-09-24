import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TakeSubjectScreen extends StatefulWidget {
  const TakeSubjectScreen({super.key});

  @override
  State<TakeSubjectScreen> createState() => _TakeSubjectScreenState();
}

class _TakeSubjectScreenState extends State<TakeSubjectScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<SubjectProvider>(context, listen: false).fetchCoursesFromApi();
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
      body:
          provider.courses.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: provider.courses.length,
                itemBuilder: (context, index) {
                  final course = provider.courses[index];
                  final isRegistered = provider.isCourseRegistered(course.id);

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        '${course.courseName} (${course.courseCode})',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'หน่วยกิต: ${course.credits}\n'
                        '${course.availabilityText}\n'
                        '${course.description.isNotEmpty ? course.description : 'ไม่มีรายละเอียด'}',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      trailing: ElevatedButton(
                        onPressed:
                            isRegistered || !course.isAvailable
                                ? null
                                : () async {
                                  try {
                                    // แสดง loading
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder:
                                          (context) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                    );

                                    await provider.registerCourse(course.id);

                                    if (mounted) {
                                      Navigator.pop(
                                        context,
                                      ); // ปิด loading dialog

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'ลงทะเบียน ${course.courseName} สำเร็จ',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      Navigator.pop(
                                        context,
                                      ); // ปิด loading dialog

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'ลงทะเบียนไม่สำเร็จ: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 3),
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
                    ),
                  );
                },
              ),
    );
  }
}
