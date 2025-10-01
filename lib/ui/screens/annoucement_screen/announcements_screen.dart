import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campusapp/models/announcement.dart';
import 'package:campusapp/ui/service/announcement_service.dart';
import 'package:campusapp/ui/screens/annoucement_screen/announcement_detail_screen.dart';
import 'package:campusapp/ui/screens/annoucement_screen/bookmarked_announcements_screen.dart';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    // Require login before allowing bookmark actions
    if (!await _isLoggedIn()) {
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

  Future<bool> _isLoggedIn() async {
    try {
      const storage = FlutterSecureStorage();
      final tokenRaw = await storage.read(key: 'access_token');
      if (tokenRaw == null || tokenRaw.isEmpty) return false;
      try {
        final parsed = jsonDecode(tokenRaw);
        if (parsed is Map && parsed['access_token'] is String) {
          return (parsed['access_token'] as String).isNotEmpty;
        }
      } catch (_) {}
      return tokenRaw.isNotEmpty;
    } catch (_) {
      return false;
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
            onPressed: () async {
              if (!await _isLoggedIn()) {
                final goLogin = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('ต้องเข้าสู่ระบบ'),
                    content: const Text('กรุณาเข้าสู่ระบบเพื่อดูบุ๊กมาร์กของคุณ'),
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

              if (!mounted) return;
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
              return const Center(
                child: Text(
                  'ไม่มีประกาศในขณะนี้\n(เมื่อออฟไลน์จะแสดงเฉพาะประกาศที่บุ๊กมาร์กไว้)',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final announcements = [...snapshot.data!];

            // Sort newest first by displayDate (createdAt -> updatedAt -> startDate)
            announcements.sort((a, b) {
              final aDate = a.displayDate ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = b.displayDate ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDate.compareTo(aDate);
            });

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
                          // Left side - Image with date below
                          SizedBox(
                            width: 100.w,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100.w,
                                  height: 100.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.r),
                                    color: Colors.grey[200],
                                  ),
                                  child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8.r),
                                          child: Image.network(
                                            item.imageUrl!,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) {
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
                                SizedBox(height: 6.h),
                                if (item.displayDate != null)
                                  Text(
                                    _formatDate(item.displayDate!),
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
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

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }
}
