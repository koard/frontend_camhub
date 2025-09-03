import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EventDetailScreen extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: Icon(
                            Icons.event,
                            size: 32.sp,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            event["name"] ?? "ไม่มีชื่อกิจกรรม",
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        "กิจกรรม",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // รายละเอียดกิจกรรม
            _buildDetailCard(
              "รายละเอียดกิจกรรม",
              event["description"] ?? "ไม่มีรายละเอียด",
              Icons.description,
              Colors.green,
            ),
            SizedBox(height: 16.h),

            // วันที่เริ่ม-สิ้นสุด
            Row(
              children: [
                Expanded(
                  child: _buildDetailCard(
                    "วันที่เริ่ม",
                    event["start_date"] ?? "-",
                    Icons.play_arrow,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildDetailCard(
                    "วันที่สิ้นสุด",
                    event["end_date"] ?? "-",
                    Icons.stop,
                    Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // ข้อมูลเพิ่มเติม
            if (event["location"] != null)
              _buildDetailCard(
                "สถานที่",
                event["location"],
                Icons.location_on,
                Colors.orange,
              ),
            if (event["location"] != null) SizedBox(height: 16.h),

            if (event["organizer"] != null)
              _buildDetailCard(
                "ผู้จัดงาน",
                event["organizer"],
                Icons.person,
                Colors.purple,
              ),
            if (event["organizer"] != null) SizedBox(height: 16.h),

            if (event["contact"] != null)
              _buildDetailCard(
                "ติดต่อ",
                event["contact"],
                Icons.phone,
                Colors.teal,
              ),
            if (event["contact"] != null) SizedBox(height: 16.h),

            // ปุ่มสำหรับการดำเนินการ
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('สนใจกิจกรรมนี้แล้ว!')),
                      );
                    },
                    icon: const Icon(Icons.favorite),
                    label: Text(
                      'สนใจกิจกรรม',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, size: 20.sp, color: color),
                ),
                SizedBox(width: 12.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
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
            ),
          ],
        ),
      ),
    );
  }
}
