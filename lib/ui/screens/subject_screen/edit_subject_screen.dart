import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';

class EditRegisteredSubjectScreen extends StatefulWidget {
  const EditRegisteredSubjectScreen({super.key});

  @override
  State<EditRegisteredSubjectScreen> createState() =>
      _EditRegisteredSubjectState();
}

class _EditRegisteredSubjectState extends State<EditRegisteredSubjectScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<SubjectProvider>(context, listen: false);
    await provider.fetchEnrollments();
    await provider.fetchCoursesFromApi();
  }

  Future<void> _unregisterCourse(int courseId, String courseName) async {
    // แสดง dialog ยืนยัน
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('ยืนยันการยกเลิกลงทะเบียน'),
            content: Text(
              'คุณต้องการยกเลิกการลงทะเบียนวิชา "$courseName" หรือไม่?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ยกเลิก'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<SubjectProvider>(context, listen: false);
      await provider.unregisterCourse(courseId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ยกเลิกการลงทะเบียนวิชา "$courseName" เรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขการลงทะเบียนรายวิชา'),
        backgroundColor: const Color(0xFF113F67),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SubjectProvider>(
        builder: (context, provider, child) {
          // กรองเฉพาะคอร์สที่ลงทะเบียนแล้ว
          final registeredCourses =
              provider.courses
                  .where((course) => provider.isCourseRegistered(course.id))
                  .toList();

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (registeredCourses.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีการลงทะเบียนวิชา',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: registeredCourses.length,
              itemBuilder: (context, index) {
                final course = registeredCourses[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'รหัสวิชา: ${course.courseCode}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'หน่วยกิต: ${course.credits}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'คำอธิบาย: ${course.description}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          course.availabilityText,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () => _unregisterCourse(
                                      course.id,
                                      course.courseName,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('ยกเลิกการลงทะเบียน'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
