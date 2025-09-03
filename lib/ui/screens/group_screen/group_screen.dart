import 'package:flutter/material.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> groupChats = [
      {
        'name': 'กลุ่มวิศวกรรมคอมพิวเตอร์',
        'lastMessage': 'ประชุมวันพรุ่งนี้ 9 โมงนะ',
      },
      {'name': 'กลุ่ม Lab 1', 'lastMessage': 'ส่งงานกันครบหรือยัง?'},
      {'name': 'ชมรมหุ่นยนต์', 'lastMessage': 'ขอบคุณที่ช่วยงานวันนี้ 🙏'},
      {'name': 'เพื่อน ม.6 รุ่น 65', 'lastMessage': 'มีใครว่างไปเที่ยวมั้ย'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('กลุ่มแชท')),
      body: ListView.builder(
        itemCount: groupChats.length,
        itemBuilder: (context, index) {
          final chat = groupChats[index];
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.group, color: Colors.white),
            ),
            title: Text(chat['name'] ?? ''),
            subtitle: Text(chat['lastMessage'] ?? ''),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // ไปหน้าแชทจริง ๆ ได้ที่นี่
              // Navigator.pushNamed(context, '/group_chat', arguments: chat);
            },
          );
        },
      ),
    );
  }
}
