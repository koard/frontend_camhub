import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../screens/events_screen/event_detail_screen.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventCard({super.key, required this.event});

  String _formatDateTimeString(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shadowColor: Colors.grey.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 8.h),
              _buildTitle(),
              SizedBox(height: 6.h),
              _buildDescription(),
              SizedBox(height: 6.h),
              _buildDateInfo(),
              SizedBox(height: 8.h),
              _buildDetailButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(Icons.event, size: 24.sp, color: Colors.blue.shade700),
        ),
        const Spacer(),
        _buildCapacityChip(),
      ],
    );
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  Widget _buildCapacityChip() {
    final enrolled = _asInt(event['enrolled_count']) ?? 0;
    final capacity = _asInt(event['capacity']);
    final text = capacity != null && capacity > 0 ? '$enrolled/$capacity' : '$enrolled';
    final isFull = capacity != null && capacity > 0 && enrolled >= capacity;
    final bg = isFull ? Colors.red.shade100 : Colors.green.shade100;
    final fg = isFull ? Colors.red.shade700 : Colors.green.shade700;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people, size: 12.sp, color: fg),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      event["name"] ?? "ไม่มีชื่อกิจกรรม",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15.sp,
        color: Colors.grey.shade800,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription() {
    return Expanded(
      child: Text(
        event["description"] ?? "ไม่มีรายละเอียด",
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.grey.shade600,
          height: 1.3,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDateInfo() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.play_arrow, size: 14.sp, color: Colors.green.shade600),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  _formatDateTimeString(event["start_date"]),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Icon(Icons.stop, size: 14.sp, color: Colors.red.shade600),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  _formatDateTimeString(event["end_date"]),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        icon: Icon(Icons.visibility, size: 16.sp),
        label: Text('ดูรายละเอียด', style: TextStyle(fontSize: 12.sp)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }
}
