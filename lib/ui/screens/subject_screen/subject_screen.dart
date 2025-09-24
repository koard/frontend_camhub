import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/subject_provider.dart';
import 'take_subject_screen.dart';
import 'edit_subject_screen.dart'; // 👈 เพิ่ม import

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลการลงทะเบียนเมื่อเข้าหน้านี้
    _loadData();
  }

  Future<void> _loadData() async {
    await Provider.of<SubjectProvider>(
      context,
      listen: false,
    ).fetchEnrollments();
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

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(
                                enrollment.courseName,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'รหัสวิชา: ${enrollment.courseId}',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  Text(
                                    'สถานะ: ${enrollment.status}',
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
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF113F67),
                                child: Text(
                                  '${enrollment.courseId}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              trailing:
                                  enrollment.status == 'enrolled'
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                      : const Icon(
                                        Icons.pending,
                                        color: Colors.orange,
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
