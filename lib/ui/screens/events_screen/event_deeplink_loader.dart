import 'package:flutter/material.dart';
import 'package:campusapp/ui/service/event_service.dart';
import 'package:campusapp/ui/screens/events_screen/event_detail_screen.dart';

class EventDeepLinkLoader extends StatefulWidget {
  final int eventId;
  const EventDeepLinkLoader({super.key, required this.eventId});

  @override
  State<EventDeepLinkLoader> createState() => _EventDeepLinkLoaderState();
}

class _EventDeepLinkLoaderState extends State<EventDeepLinkLoader> {
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final data = await EventService.fetchPublicById(widget.eventId);
      if (!mounted) return;
      if (data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบกิจกรรมหรือปิดการเข้าถึง')),
        );
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: data)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปิดกิจกรรมไม่สำเร็จ: $e')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
