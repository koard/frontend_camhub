import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';

class TakeSubjectScreen extends StatefulWidget {
  const TakeSubjectScreen({super.key});

  @override
  State<TakeSubjectScreen> createState() => _TakeSubjectScreenState();
}

class _TakeSubjectScreenState extends State<TakeSubjectScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<SubjectProvider>(context, listen: false).loadSubjects();
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
          provider.subjects.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: provider.subjects.length,
                itemBuilder: (context, index) {
                  final subject = provider.subjects[index];
                  final isRegistered = provider.isRegistered(subject.subjectId);

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
                        onPressed:
                            isRegistered
                                ? null
                                : () =>
                                    provider.registerSubject(subject.subjectId),
                        child: Text(
                          isRegistered ? 'ลงทะเบียนแล้ว' : 'ลงทะเบียน',
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
