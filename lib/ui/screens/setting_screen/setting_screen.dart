import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Mock notification settings
  bool _subjectNotifications = false;
  bool _activityNotifications = false;
  bool _attendanceNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('การตั้งค่า', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: const Color(0xFF113F67),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Notification Settings Section
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications,
                        color: const Color(0xFF113F67),
                        size: 24.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'การแจ้งเตือน',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF113F67),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Subject Notifications Toggle
                  _buildNotificationToggle(
                    title: 'แจ้งเตือนรายวิชา',
                    subtitle: 'รับการแจ้งเตือนเกี่ยวกับรายวิชาและการเรียน',
                    value: _subjectNotifications,
                    onChanged: (value) {
                      setState(() {
                        _subjectNotifications = value;
                      });
                      _showToggleSnackBar('แจ้งเตือนรายวิชา', value);
                    },
                    icon: Icons.school,
                  ),

                  Divider(height: 24.h, thickness: 0.5),

                  // Activity Notifications Toggle
                  _buildNotificationToggle(
                    title: 'แจ้งเตือนกิจกรรม',
                    subtitle: 'รับการแจ้งเตือนเกี่ยวกับกิจกรรมและเหตุการณ์',
                    value: _activityNotifications,
                    onChanged: (value) {
                      setState(() {
                        _activityNotifications = value;
                      });
                      _showToggleSnackBar('แจ้งเตือนกิจกรรม', value);
                    },
                    icon: Icons.event,
                  ),

                  Divider(height: 24.h, thickness: 0.5),

                  // Attendance Notifications Toggle
                  _buildNotificationToggle(
                    title: 'แจ้งเตือนการเข้าเรียน',
                    subtitle:
                        'รับการแจ้งเตือนเกี่ยวกับการเข้าเรียนและการขาดเรียน',
                    value: _attendanceNotifications,
                    onChanged: (value) {
                      setState(() {
                        _attendanceNotifications = value;
                      });
                      _showToggleSnackBar('แจ้งเตือนการเข้าเรียน', value);
                    },
                    icon: Icons.assignment_turned_in,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
      color:
        value
          ? const Color(0xFF113F67).withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: value ? const Color(0xFF113F67) : Colors.grey[600],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF113F67),
          activeTrackColor: const Color(0xFF113F67).withValues(alpha: 0.3),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[300],
        ),
      ],
    );
  }

  void _showToggleSnackBar(String settingName, bool isEnabled) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$settingName${isEnabled ? ' เปิดใช้งาน' : ' ปิดใช้งาน'}แล้ว',
          style: TextStyle(fontSize: 14.sp),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: isEnabled ? const Color(0xFF113F67) : Colors.grey[600],
      ),
    );
  }
}
