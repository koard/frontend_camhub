import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campusapp/models/announcement.dart';
import 'package:campusapp/ui/service/announcement_service.dart';

class AnnouncementScreen extends StatelessWidget {
  const AnnouncementScreen({super.key});

  String _truncateText(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประกาศ', style: TextStyle(fontSize: 20.sp)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Announcement>>(
        future: AnnouncementService.fetchAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดประกาศ'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีประกาศในขณะนี้'));
          }

          final announcements = snapshot.data!;

          return Padding(
            padding: EdgeInsets.all(8.w),
            child: GridView.builder(
              itemCount: announcements.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8.h,
                crossAxisSpacing: 8.w,
                childAspectRatio: 3 / 4,
              ),
              itemBuilder: (context, index) {
                final item = announcements[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.announcement,
                          size: 36.sp,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _truncateText(item.description),
                          style: TextStyle(fontSize: 12.sp),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          "ประกาศโดย: ${item.author ?? '-'}",
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        Text(
                          "วันที่: ${item.date ?? '-'}",
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
