import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campusapp/models/announcement.dart';
import 'package:campusapp/ui/service/announcement_service.dart';
import 'package:campusapp/core/auth/auth_utils.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  bool isBookmarked = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    try {
      final service = AnnouncementService();
      final bookmarked = await service.isAnnouncementBookmarked(
        widget.announcement.id,
      );
      if (mounted) {
        setState(() {
          isBookmarked = bookmarked;
        });
      }
    } catch (e) {
      // Handle error silently, bookmark status will remain as false
    }
  }

  Future<void> _toggleBookmark() async {
    if (isLoading) return;

  // Require login before allowing bookmark actions
    if (!await AuthUtils.isLoggedIn()) {
      if (!mounted) return;
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ต้องเข้าสู่ระบบ'),
          content: const Text('กรุณาเข้าสู่ระบบเพื่อใช้งานบุ๊กมาร์ก'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('เข้าสู่ระบบ'),
            ),
          ],
        ),
      );
      if (goLogin == true && mounted) {
        Navigator.pushNamed(context, '/login');
      }
      return;
    }

    setState(() {
      isLoading = true;
    });

    final service = AnnouncementService();
    bool success;

    if (isBookmarked) {
      success = await service.deleteBookmark(widget.announcement.id);
    } else {
      success = await service.createBookmark(widget.announcement.id);
    }

    setState(() {
      isLoading = false;
      if (success) {
        isBookmarked = !isBookmarked;
      }
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBookmarked ? 'บุ๊กมาร์กแล้ว' : 'ลบบุ๊กมาร์กแล้ว'),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด')));
    }
  }
  String _formatDateOnly(DateTime? date) {
    if (date == null) return 'ไม่ระบุ';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }


  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    Color? iconColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? const Color(0xFF113F67), size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  content,
                  style: TextStyle(fontSize: 15.sp, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (widget.announcement.imageUrl == null ||
        widget.announcement.imageUrl!.isEmpty) {
      return Container(
        height: 200.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.announcement_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8.h),
            Text(
              'ไม่มีรูปภาพ',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250.h,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Image.network(
          widget.announcement.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey[100],
              child: Center(
                child: CircularProgressIndicator(
                  value:
                      loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                  color: const Color(0xFF113F67),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[100],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 48.sp,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'ไม่สามารถโหลดรูปภาพได้',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดประกาศ'),
        backgroundColor: const Color(0xFF113F67),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: isLoading ? null : _toggleBookmark,
            icon:
                isLoading
                    ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            _buildImageSection(),

            SizedBox(height: 20.h),

            // Title
            Text(
              widget.announcement.title,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF113F67),
                height: 1.3,
              ),
            ),

            SizedBox(height: 8.h),

            SizedBox(height: 12.h),

            // Description Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: const Color(0xFF113F67),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'รายละเอียด',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF113F67),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'หมวดหมู่: ${widget.announcement.category}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.announcement.description,
                    style: TextStyle(
                      fontSize: 15.sp,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // Information Cards
            _buildInfoCard(
              icon: Icons.schedule,
              title: 'วันที่เริ่มต้น',
              content: _formatDateOnly(widget.announcement.startDate),
              iconColor: Colors.green[600],
            ),

            _buildInfoCard(
              icon: Icons.event,
              title: 'วันที่สิ้นสุด',
              content: _formatDateOnly(widget.announcement.endDate),
              iconColor: Colors.red[600],
            ),
          ],
        ),
      ),
    );
  }
}
