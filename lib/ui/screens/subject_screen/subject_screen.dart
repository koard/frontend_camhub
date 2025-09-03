import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import 'take_subject_screen.dart';
import 'edit_subject_screen.dart'; // 👈 เพิ่ม import

class SubjectScreen extends StatelessWidget {
  const SubjectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);

    // รายวิชาที่ลงทะเบียนแล้ว
    final registeredSubjects =
        provider.subjects
            .where((subject) => provider.isRegistered(subject.subjectId))
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TakeSubjectScreen(),
                        ),
                      );
                    },
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
            child:
                registeredSubjects.isEmpty
                    ? const Center(child: Text('ยังไม่มีการลงทะเบียนวิชา'))
                    : ListView.builder(
                      itemCount: registeredSubjects.length,
                      itemBuilder: (context, index) {
                        final subject = registeredSubjects[index];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            title: Text(
                              '${subject.subject} (${subject.subjectId})',
                            ),
                            subtitle: Text(
                              'ผู้สอน: ${subject.teacher}\n'
                              'วัน: ${subject.day} เวลา: ${subject.startTime} - ${subject.endTime}\n'
                              'ห้อง: ${subject.room} หน่วยกิต: ${subject.credit}',
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
