import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../screens/events_screen/event_detail_screen.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.grey.withOpacity(0.3),
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
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 12.h),
              _buildTitle(),
              SizedBox(height: 8.h),
              _buildDescription(),
              SizedBox(height: 8.h),
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
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            "กิจกรรม",
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      event["name"] ?? "ไม่มีชื่อกิจกรรม",
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16.sp,
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
          fontSize: 12.sp,
          color: Colors.grey.shade600,
          height: 1.3,
        ),
        maxLines: 2,
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
                  event["start_date"] ?? "-",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
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
                  event["end_date"] ?? "-",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
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
