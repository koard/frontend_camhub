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
  @override
  void initState() {
    super.initState();
    Provider.of<SubjectProvider>(context, listen: false).loadSubjects();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);

    final registeredSubjects =
        provider.subjects
            .where((subject) => provider.isRegistered(subject.subjectId))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขการทะเบียนรายวิชา'),
        backgroundColor: const Color(0xFF113F67),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
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
                      title: Text('${subject.subject} (${subject.subjectId})'),
                      subtitle: Text(
                        'ผู้สอน: ${subject.teacher}\n'
                        'วัน: ${subject.day} เวลา: ${subject.startTime} - ${subject.endTime}\n'
                        'ห้อง: ${subject.room} หน่วยกิต: ${subject.credit}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          provider.unregisteredSubject(subject.subjectId);
                          setState(() {}); // refresh UI
                        },
                        child: const Text('ยกเลิกรายวิชา'),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
