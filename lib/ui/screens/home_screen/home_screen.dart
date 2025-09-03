import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campusapp/models/announcement.dart';
import 'package:campusapp/ui/service/announcement_service.dart';
import 'package:campusapp/models/event.dart';
import 'package:campusapp/ui/service/event_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  // Banner images (network)
  final List<String> _bannerImages = [
    'https://www.runlah.com/images/event/YYS2wHAG/bn_ir-th.webp',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSYcyVIf5s3mzwc5FTldiF4a8bRi0aWCxu5kQ&s',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRb43FQ6Cy2KUjD1PuJRjhS7j4u20sOAAK3ww&s',
  ];

  int get bannerCount => _bannerImages.length;

  late Future<List<Announcement>> _announcementFuture;
  late Future<List<Event>> _eventFuture;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();

    // ✅ Initialize futures only once
    _announcementFuture = AnnouncementService.fetchLatest();
    _eventFuture = EventService.fetchLatest();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < bannerCount - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (mounted) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        setState(() {}); // only for dot indicator
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Campus Life Hub', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: const Color(0xFF113F67),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Banner Section
              SizedBox(
                height: 180.h,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: bannerCount,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _timer?.cancel();
                    _startAutoSlide(); // restart timer
                  },
                  itemBuilder: (context, index) {
                    final imgUrl = _bannerImages[index];
                    return Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        color: Colors.blue[200],
                      ),
                      child: Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          final value =
                              progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null;
                          return Center(
                            child: SizedBox(
                              width: 32.w,
                              height: 32.w,
                              child: CircularProgressIndicator(value: value),
                            ),
                          );
                        },
                        errorBuilder:
                            (context, error, stack) => Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 40.sp,
                              ),
                            ),
                      ),
                    );
                  },
                ),
              ),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  bannerCount,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 8.h,
                    ),
                    width: _currentPage == i ? 16.w : 8.w,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: _currentPage == i ? Colors.blue : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
              ),

              // Announcements Section
              _buildSectionHeader("Announcements", '/announcements'),
              _buildAnnouncementList(),

              // Events Section
              _buildSectionHeader("Events", '/events'),
              _buildEventList(),

              // Tools Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tools',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _buildToolButton(
                    Icons.school,
                    'ค้นหาวิชา',
                    onTap: () => Navigator.pushNamed(context, '/exampleInfo'),
                  ),
                  _buildToolButton(
                    Icons.computer,
                    'ลงทะเบียน',
                    onTap: () => Navigator.pushNamed(context, '/subject'),
                  ),
                  _buildToolButton(
                    Icons.group,
                    'Group',
                    onTap: () => Navigator.pushNamed(context, '/group'),
                  ),
                  _buildToolButton(
                    Icons.map,
                    'Map',
                    onTap: () => Navigator.pushNamed(context, '/map'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section Header
  Widget _buildSectionHeader(String title, String route) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                "What's new",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, route),
            child: Text(
              'view all',
              style: TextStyle(color: Colors.blue, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  // Announcements list
  Widget _buildAnnouncementList() {
    return SizedBox(
      height: 130.h,
      child: FutureBuilder<List<Announcement>>(
        future: _announcementFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text('ไม่มีประกาศ', style: TextStyle(fontSize: 14.sp)),
            );
          }

          final data = snapshot.data!;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: data.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final item = data[index];
              return _buildCard(item.title, item.description, item.date);
            },
          );
        },
      ),
    );
  }

  // Events list
  Widget _buildEventList() {
    return SizedBox(
      height: 130.h,
      child: FutureBuilder<List<Event>>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text('ไม่มีกิจกรรม', style: TextStyle(fontSize: 14.sp)),
            );
          }

          final data = snapshot.data!;
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: data.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final item = data[index];
              return _buildCard(item.name, item.description, item.startDate);
            },
          );
        },
      ),
    );
  }

  // Shared card widget
  Widget _buildCard(String title, String description, DateTime? date) {
    return Container(
      width: 200.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4.r)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            description,
            style: TextStyle(fontSize: 12.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            date != null ? '${date.day}/${date.month}/${date.year}' : '',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Tool button
  Widget _buildToolButton(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF113F67),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
