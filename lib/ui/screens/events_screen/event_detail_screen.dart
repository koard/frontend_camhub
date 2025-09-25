import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../service/event_enrollment_service.dart';

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
      final enrolled = await EventEnrollmentService.isEnrolled(eventId);
      final total = await EventEnrollmentService.getTotalEnrolled(eventId);
      if (!mounted) return;
      setState(() {
        _enrolled = enrolled;
        _enrolledCount = total;
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

            // ความคืบหน้าการลงทะเบียน
            if (showCapacity)
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
                          Icon(Icons.people_alt, color: Colors.blue.shade600),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: LinearProgressIndicator(
                          value: ((enrolled / capacity).clamp(0, 1)).toDouble(),
                          minHeight: 10.h,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            enrolled >= capacity
                                ? Colors.red.shade400
                                : Colors.green.shade400,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'ลงทะเบียนแล้ว ${enrolled}/${capacity} คน',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
                      ),
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

            // วันที่เริ่ม-สิ้นสุด (compact tiles)
            _buildDateRow(
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('แชร์กิจกรรมแล้ว!')),
                      );
                    },
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

  Widget _buildDateRow({String? startIso, String? endIso}) {
    final start = _splitDateTime(startIso);
    final end = _splitDateTime(endIso);
    return Row(
      children: [
        Expanded(
          child: _buildDateTile(
            title: 'วันที่เริ่ม',
            date: start.date,
            time: start.time,
            color: Colors.blue,
            icon: Icons.play_arrow,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildDateTile(
            title: 'วันที่สิ้นสุด',
            date: end.date,
            time: end.time,
            color: Colors.red,
            icon: Icons.stop,
          ),
        ),
      ],
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

  Widget _buildDateTile({
    required String title,
    required String date,
    required String time,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(14.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 18.sp, color: color),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
}

class _DateParts {
  final String date;
  final String time;
  const _DateParts(this.date, this.time);
}
