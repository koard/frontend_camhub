import 'package:flutter/material.dart';
import 'package:campusapp/models/course.dart';
import '../../service/course_services.dart';

class ExampleInfoScreen extends StatefulWidget {
  const ExampleInfoScreen({super.key});

  @override
  State<ExampleInfoScreen> createState() => _ExampleInfoScreenState();
}

class _ExampleInfoScreenState extends State<ExampleInfoScreen> {
  // Controller สำหรับ TextField (ช่องค้นหา)
  final TextEditingController _searchController = TextEditingController();

  // เก็บรายวิชาทั้งหมดที่โหลดมาจาก service
  final List<Course> _allCourses = [];

  // เก็บรายวิชาที่ผ่านการกรองจากช่องค้นหา
  List<Course> _filteredCourses = [];

  // Service สำหรับเรียก API รายวิชา
  final CourseService _service = CourseService();

  // ตัวแปร state
  bool _isLoading = true; // สถานะโหลดข้อมูล
  String? _errorMessage; // ข้อความ error (ถ้ามี)

  @override
  void initState() {
    super.initState();
    _fetchCourses(); // โหลดข้อมูลรายวิชาทันทีเมื่อเปิดหน้าจอ
    _searchController.addListener(
      _filterCourses,
    ); // ฟังการเปลี่ยนแปลงของช่องค้นหา
  }

  @override
  void dispose() {
    // ทำความสะอาด controller ก่อนปิดหน้า
    _searchController.dispose();
    super.dispose();
  }

  /// ดึงข้อมูลรายวิชาจาก service
  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true; // เริ่มโหลด
      _errorMessage = null;
    });

    try {
      // โหลดข้อมูลรายวิชาจาก API
      final courses = await _service.getCourses();

      // เคลียร์ของเก่าแล้วเพิ่มข้อมูลใหม่
      _allCourses
        ..clear()
        ..addAll(courses);

      _filterCourses(); // กรองตาม query ล่าสุด (ถ้ามี)
    } catch (e) {
      // ถ้าโหลดล้มเหลว แสดง error
      setState(() {
        _errorMessage = 'โหลดรายวิชาไม่สำเร็จ';
      });
    } finally {
      // เมื่อโหลดเสร็จ ปิด loading
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// กรองรายวิชาตามคำค้นหา
  void _filterCourses() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        // ถ้าไม่พิมพ์อะไร แสดงรายวิชาทั้งหมด
        _filteredCourses = List.of(_allCourses);
      } else {
        // ถ้าพิมพ์ → กรองตามชื่อวิชา หรือ รหัสวิชา
        _filteredCourses =
            _allCourses.where((course) {
              return course.courseName.toLowerCase().contains(query) ||
                  course.courseCode.toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  /// สร้างช่องค้นหา
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'พิมพ์ชื่อวิชา หรือ รหัสวิชา เช่น CS101',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), // ขอบโค้งมน
          ),
        ),
      ),
    );
  }

  /// สร้าง ListTile สำหรับรายวิชาแต่ละตัว
  Widget _buildCourseTile(Course course) {
    final remainingSeats = course.availableSeats - course.enrolledCount;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF113F67),
        child: Text(
          // เอาตัวอักษรแรกของรหัสวิชามาแสดง ถ้าไม่มีใช้ "?"
          course.courseCode.isNotEmpty
              ? course.courseCode[0].toUpperCase()
              : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text('${course.courseName} (${course.courseCode})'),
      subtitle: Text(
        'หน่วยกิต: ${course.credits} • ที่นั่งคงเหลือ: $remainingSeats/${course.availableSeats}',
      ),
      onTap: () {
        // TODO: เพิ่มฟังก์ชันกดเข้าไปดูรายละเอียดรายวิชาในอนาคต
      },
    );
  }

  /// ส่วนแสดงผลหลัก (loading, error, empty, list)
  Widget _buildBody() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()), // วงกลมโหลด
      );
    }

    if (_errorMessage != null) {
      return Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.black),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_filteredCourses.isEmpty) {
      return const Expanded(
        child: Center(child: Text('ไม่พบรายวิชาที่ตรงกับคำค้นหา')),
      );
    }

    // ถ้ามีข้อมูล → แสดง ListView
    return Expanded(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _filteredCourses.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder:
            (context, index) => _buildCourseTile(_filteredCourses[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหารายวิชา'),
        backgroundColor: const Color(0xFF113F67),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCourses, // ดึงข้อมูลใหม่เมื่อดึงหน้าจอลง
        child: Column(
          children: [
            _buildSearchField(), // ช่องค้นหา
            _buildBody(), // แสดงผลตามสถานะ
          ],
        ),
      ),
    );
  }
}
