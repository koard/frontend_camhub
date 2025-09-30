import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campusapp/models/announcement.dart';
import 'package:campusapp/ui/service/announcement_service.dart';
import 'package:campusapp/ui/screens/annoucement_screen/announcement_detail_screen.dart';

class BookmarkedAnnouncementsScreen extends StatefulWidget {
  const BookmarkedAnnouncementsScreen({super.key});

  @override
  State<BookmarkedAnnouncementsScreen> createState() =>
      _BookmarkedAnnouncementsScreenState();
}

class _BookmarkedAnnouncementsScreenState
    extends State<BookmarkedAnnouncementsScreen> {
  late Future<List<Announcement>> futureBookmarks;

  @override
  void initState() {
    super.initState();
    futureBookmarks = _fetchBookmarks();
  }

  Future<List<Announcement>> _fetchBookmarks() async {
    final service = AnnouncementService();
    return await service.getBookmarkedAnnouncements();
  }

  String _truncateText(String text, {int maxLength = 80}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _removeBookmark(Announcement announcement) async {
    final service = AnnouncementService();
    final success = await service.deleteBookmark(announcement.id);

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบบุ๊กมาร์กเรียบร้อยแล้ว')));
      setState(() {
        futureBookmarks = _fetchBookmarks(); // Refresh list
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบบุ๊กมาร์ก')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประกาศที่บุ๊กมาร์ก', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: const Color(0xFF113F67),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureBookmarks = _fetchBookmarks();
          });
          await futureBookmarks;
        },
        child: FutureBuilder<List<Announcement>>(
          future: futureBookmarks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('เกิดข้อผิดพลาดในการโหลดบุ๊กมาร์ก'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('ไม่มีประกาศที่บุ๊กมาร์กไว้'));
            }

            final bookmarks = snapshot.data!;

            return Padding(
              padding: EdgeInsets.all(8.w),
              child: ListView.builder(
                itemCount: bookmarks.length,
                itemBuilder: (context, index) {
                  final item = bookmarks[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    margin: EdgeInsets.only(bottom: 12.h),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          // Left side - Image
                          Container(
                            width: 100.w,
                            height: 100.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.r),
                              color: Colors.grey[200],
                            ),
                            child:
                                item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8.r),
                                      child: Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value:
                                                  loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Icon(
                                            Icons.announcement,
                                            size: 36.sp,
                                            color: Colors.orange,
                                          );
                                        },
                                      ),
                                    )
                                    : Icon(
                                      Icons.announcement,
                                      size: 36.sp,
                                      color: Colors.orange,
                                    ),
                          ),
                          SizedBox(width: 16.w),
                          // Right side - Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF113F67),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeBookmark(item),
                                      icon: Icon(
                                        Icons.bookmark_remove,
                                        color: Colors.red[600],
                                        size: 24.sp,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  _truncateText(item.description),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 12.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  AnnouncementDetailScreen(
                                                    announcement: item,
                                                  ),
                                        ),
                                      );
                                    },
                                    icon: Icon(Icons.visibility, size: 16.sp),
                                    label: Text(
                                      'ดูรายละเอียด',
                                      style: TextStyle(fontSize: 12.sp),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF113F67),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8.h,
                                        horizontal: 12.w,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      elevation: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}
