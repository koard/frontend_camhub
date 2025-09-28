import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../service/event_enrollment_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../service/event_share_service.dart';
import '../../service/event_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:campusapp/core/routes.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _loading = false;
  bool _enrolled = false;
  int? _enrolledCount;


  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  Future<void> _loadEnrollmentState() async {
    try {
      final eventId = _asInt(widget.event['id']);
      if (eventId == null) return;

      // 1) Always try public endpoint for enrolled_count so guests can see the number
      int? publicCount;
      try {
        final public = await EventService.fetchPublicById(eventId);
        publicCount = _asInt(public?['enrolled_count']);
      } catch (_) {}

      // 2) Auth-based checks (safe if not logged in: falls back to false/0)
      bool enrolled = false;
      try {
        enrolled = await EventEnrollmentService.isEnrolled(eventId);
      } catch (_) {}

      int? total = publicCount;
      // If public endpoint didn't provide the count, try the private count as a fallback
      if (total == null) {
        try {
          total = await EventEnrollmentService.getTotalEnrolled(eventId);
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _enrolled = enrolled;
        // Only set when we actually have a value; avoid overriding with 0 due to auth failures
        if (total != null) {
          _enrolledCount = total;
        }
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _enrolledCount = _asInt(widget.event['enrolled_count']);
    _loadEnrollmentState();
  }

  @override
  Widget build(BuildContext context) {
    final enrolled = _enrolledCount ?? _asInt(widget.event['enrolled_count']);
    final capacity = _asInt(widget.event['capacity']);
    final showCapacity = enrolled != null && capacity != null && capacity > 0;
  final isFull = showCapacity && enrolled >= capacity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดกิจกรรม'),
        backgroundColor: const Color(0xFF113F67),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                  ),
                ),
                padding: EdgeInsets.all(20.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: Icon(Icons.event, size: 32.sp, color: Colors.white),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Text(
                        widget.event["name"] ?? "ไม่มีชื่อกิจกรรม",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // ความคืบหน้าการลงทะเบียน / จำนวนนับผู้ลงทะเบียน
            if (enrolled != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people_alt, color: isFull ? Colors.red.shade600 : Colors.blue.shade600),
                          SizedBox(width: 8.w),
                          Text(
                            'การลงทะเบียน',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      if (showCapacity) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: LinearProgressIndicator(
                            value: ((enrolled / capacity).clamp(0, 1)).toDouble(),
                            minHeight: 10.h,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isFull ? Colors.red.shade400 : Colors.green.shade400,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'ลงทะเบียนแล้ว ${enrolled}/${capacity} คน',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isFull ? Colors.red.shade700 : Colors.grey.shade700,
                            fontWeight: isFull ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ] else ...[
                        // ไม่จำกัดจำนวน: แสดงเฉพาะจำนวนปัจจุบัน
                        Text(
                          'ลงทะเบียนแล้ว ${enrolled} คน',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            SizedBox(height: 12.h),

            // รายละเอียดกิจกรรม
            _buildDetailCard(
              "รายละเอียดกิจกรรม",
              widget.event["description"] ?? "ไม่มีรายละเอียด",
              Icons.description,
              Colors.green,
            ),

            SizedBox(height: 16.h),

            // วันเวลา: รวมวันที่เริ่มและสิ้นสุดไว้ในการ์ดเดียว
            _buildDateCard(
              startIso: widget.event["start_date"],
              endIso: widget.event["end_date"],
            ),

            SizedBox(height: 16.h),

            // ข้อมูลเพิ่มเติม
            if (widget.event["location"] != null && (widget.event["location"] as String).isNotEmpty)
              _buildDetailCard(
                "สถานที่",
                widget.event["location"],
                Icons.location_on,
                Colors.orange,
              ),
            if (widget.event["location"] != null && (widget.event["location"] as String).isNotEmpty)
              SizedBox(height: 16.h),

            if (widget.event["organizer"] != null && (widget.event["organizer"] as String).isNotEmpty)
              _buildDetailCard(
                "ผู้จัดงาน",
                widget.event["organizer"],
                Icons.person,
                Colors.purple,
              ),
            if (widget.event["organizer"] != null && (widget.event["organizer"] as String).isNotEmpty)
              SizedBox(height: 16.h),

            if (widget.event["contact"] != null && (widget.event["contact"] as String).isNotEmpty)
              _buildDetailCard(
                "ติดต่อ",
                widget.event["contact"],
                Icons.phone,
                Colors.teal,
              ),
            if (widget.event["contact"] != null && (widget.event["contact"] as String).isNotEmpty)
              SizedBox(height: 16.h),

            // ปุ่มสำหรับการดำเนินการ
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(child: _buildEnrollButton(showCapacity: showCapacity, eventCapacity: capacity, currentEnrolled: enrolled)),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _onPressShare,
                    icon: const Icon(Icons.share),
                    label: Text('แชร์', style: TextStyle(fontSize: 16.sp)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade400,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, size: 20.sp, color: color),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              content,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard({String? startIso, String? endIso}) {
    final start = _splitDateTime(startIso);
    final end = _splitDateTime(endIso);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // เริ่ม (ซ้าย)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.play_arrow, size: 18.sp, color: Colors.blue),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เริ่ม',
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            start.date,
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            start.time,
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Divider แนวตั้ง
              VerticalDivider(width: 24, thickness: 1, color: Colors.grey.shade200),
              // สิ้นสุด (ขวา)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.stop, size: 18.sp, color: Colors.red),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สิ้นสุด',
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            end.date,
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            end.time,
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Returns date and time strings
  _DateParts _splitDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return const _DateParts('-', '-');
    final dt = DateTime.tryParse(iso);
    if (dt == null) return const _DateParts('-', '-');
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${two(dt.day)}/${two(dt.month)}/${dt.year}';
    final time = '${two(dt.hour)}:${two(dt.minute)}';
    return _DateParts(date, time);
  }

  // ... (ยกเลิก _buildDateTile และใช้ _buildDateCard แทน)

  Widget _buildEnrollButton({required bool showCapacity, int? eventCapacity, int? currentEnrolled}) {
    final isFull = showCapacity && eventCapacity != null && currentEnrolled != null && currentEnrolled >= eventCapacity;
    final canPress = !_loading && (!isFull || _enrolled);
    final label = _enrolled ? 'ยกเลิกลงทะเบียน' : 'ลงทะเบียน';
    final color = _enrolled ? Colors.orange.shade600 : const Color(0xFF113F67);
    return ElevatedButton.icon(
      onPressed: canPress ? _onPressEnroll : null,
      icon: Icon(_enrolled ? Icons.cancel : Icons.person_add_alt_1),
      label: _loading
          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label, style: TextStyle(fontSize: 16.sp)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }

  Future<void> _onPressEnroll() async {
    // Require login before allowing enroll/cancel
    if (!await _isLoggedIn()) {
      if (!mounted) return;
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ต้องเข้าสู่ระบบ'),
          content: const Text('กรุณาเข้าสู่ระบบก่อนลงทะเบียนกิจกรรม'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('เข้าสู่ระบบ')),
          ],
        ),
      );
      if (goLogin == true && mounted) {
        Navigator.of(context).pushNamed(AppRoutes.login);
      }
      return;
    }

    final eventId = _asInt(widget.event['id']);
    if (eventId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_enrolled ? 'ยืนยันการยกเลิก' : 'ยืนยันการลงทะเบียน'),
        content: Text(_enrolled ? 'ต้องการยกเลิกการลงทะเบียนกิจกรรมนี้หรือไม่?' : 'ต้องการลงทะเบียนเข้าร่วมกิจกรรมนี้หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ยืนยัน')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    try {
      if (_enrolled) {
        await EventEnrollmentService.cancel(eventId);
        setState(() {
          _enrolled = false;
          if (_enrolledCount != null && _enrolledCount! > 0) _enrolledCount = _enrolledCount! - 1;
        });
      } else {
        await EventEnrollmentService.enroll(eventId);
        setState(() {
          _enrolled = true;
          _enrolledCount = (_enrolledCount ?? 0) + 1;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _isLoggedIn() async {
    try {
      const storage = FlutterSecureStorage();
      final tokenJson = await storage.read(key: 'access_token');
      if (tokenJson == null || tokenJson.isEmpty) return false;
      final data = jsonDecode(tokenJson);
      final token = data['access_token'];
      return token is String && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onPressShare() async {
    // Build public share URL based on backend `/api/events/public/{id}`
    final id = _asInt(widget.event['id']);
    if (id == null) return;
  final text = EventShareService.composeShareText(widget.event);
    try {
      await Share.share(text, subject: EventShareService.titleFrom(widget.event));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถแชร์ได้: $e')),
      );
    }
  }
}

class _DateParts {
  final String date;
  final String time;
  const _DateParts(this.date, this.time);
}
