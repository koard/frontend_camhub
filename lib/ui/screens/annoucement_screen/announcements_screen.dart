import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campusapp/models/announcement.dart';
import 'package:campusapp/ui/service/announcement_service.dart';
import 'package:campusapp/ui/screens/annoucement_screen/announcement_detail_screen.dart';
import 'package:campusapp/ui/screens/annoucement_screen/bookmarked_announcements_screen.dart';
import 'dart:developer';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen>
    with WidgetsBindingObserver {
  Future<List<Announcement>>? futureAnnouncements;
  final Set<int> bookmarkedIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    futureAnnouncements = _fetchAnnouncements();
    _loadBookmarkedIds();
  }

  Future<void> _loadBookmarkedIds() async {
    try {
      final service = AnnouncementService();
      final bookmarkIds = await service.getBookmarkedAnnouncementIds();
      if (mounted) {
        setState(() {
          bookmarkedIds.clear();
          bookmarkedIds.addAll(bookmarkIds);
        });
        log('[AnnouncementsScreen] Loaded ${bookmarkIds.length} bookmark IDs');
      }
    } catch (e) {
      log('[AnnouncementsScreen] Error loading bookmark IDs: $e');
    }
  }

  Future<void> _toggleBookmark(Announcement announcement) async {
    final service = AnnouncementService();
    final isBookmarked = bookmarkedIds.contains(announcement.id);

    bool success;
    if (isBookmarked) {
      success = await service.deleteBookmark(announcement.id);
    } else {
      success = await service.createBookmark(announcement.id);
    }

    if (success) {
      setState(() {
        if (isBookmarked) {
          bookmarkedIds.remove(announcement.id);
        } else {
          bookmarkedIds.add(announcement.id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBookmarked ? 'ลบบุ๊กมาร์กแล้ว' : 'บุ๊กมาร์กแล้ว'),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด')));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<List<Announcement>> _fetchAnnouncements() async {
    final service = AnnouncementService();
    return await service.getAnnouncements();
  }

  // Persist latest resolved announcements when app goes background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistCurrentAnnouncementSnapshot();
    }
  }

  Future<void> _persistCurrentAnnouncementSnapshot() async {
    try {
      if (!mounted || futureAnnouncements == null) return;
      // Best effort: await with timeout small to avoid blocking.
      final data = await futureAnnouncements!.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () => <Announcement>[],
      );
      if (data.isNotEmpty) {
        await AnnouncementService().persistAnnouncementToFile(data);
      }
    } catch (_) {
      // ignore best-effort errors
    }
  }

  String _truncateText(String text, {int maxLength = 50}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ประกาศ', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: const Color(0xFF113F67),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookmarkedAnnouncementsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureAnnouncements = _fetchAnnouncements();
          });
          await futureAnnouncements;
        },
        child: FutureBuilder<List<Announcement>>(
          future: futureAnnouncements,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดประกาศ'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(50.w), // เปลี่ยนจาก 50 เป็น 50.w
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // เพิ่มบรรทัดนี้
                    mainAxisSize: MainAxisSize.min, // เพิ่มบรรทัดนี้
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 48.sp,
                        color: Colors.grey,
                      ), // เปลี่ยนจาก 48 เป็น 48.sp
                      SizedBox(height: 16.h), // เพิ่ม SizedBox เพื่อเว้นระยะ
                      Text(
                        'ไม่มีประกาศในขณะนี้\n(เมื่อออฟไลน์จะแสดงเฉพาะประกาศที่บุ๊กมาร์กไว้)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          // เพิ่ม style
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final announcements = snapshot.data!;

            return Padding(
              padding: EdgeInsets.all(8.w),
              child: ListView.builder(
                itemCount: announcements.length,
                itemBuilder: (context, index) {
                  final item = announcements[index];
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
                                          if (loadingProgress == null) {
                                            return child;
                                          }
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
                                      onPressed: () => _toggleBookmark(item),
                                      icon: Icon(
                                        bookmarkedIds.contains(item.id)
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                        color:
                                            bookmarkedIds.contains(item.id)
                                                ? Colors.orange[600]
                                                : Colors.grey[600],
                                        size: 24.sp,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'หมวดหมู่: ${item.category}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _truncateText(
                                    item.description,
                                    maxLength: 80,
                                  ),
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
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  AnnouncementDetailScreen(
                                                    announcement: item,
                                                  ),
                                        ),
                                      );
                                      // Refresh bookmark status after returning
                                      _loadBookmarkedIds();
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
