import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DateRangeSelector extends StatelessWidget {
  final DateTimeRange? selectedDateRange;
  final VoidCallback onSelectDateRange;
  final VoidCallback onClearDateRange;

  const DateRangeSelector({
    super.key,
    required this.selectedDateRange,
    required this.onSelectDateRange,
    required this.onClearDateRange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.w),
      child: Column(
        children: [
          _buildSelectButton(),
          if (selectedDateRange != null) _buildSelectedRange(),
        ],
      ),
    );
  }

  Widget _buildSelectButton() {
    // ปุ่มเลือกช่วงวันที่
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          const Spacer(flex: 2),
          Expanded(
            flex: 6,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: onSelectDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(
                  "เลือกช่วงวันที่",
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildSelectedRange() {
    // แสดงช่วงวันที่ที่เลือก

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.blue.shade200, width: 1.5),
        ),
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: _buildStartDateCard()),
                SizedBox(width: 12.w),
                _buildArrow(),
                SizedBox(width: 12.w),
                Expanded(child: _buildEndDateCard()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // หัวข้อและปุ่มลบ
    return Row(
      children: [
        Icon(Icons.filter_alt, color: Colors.blue.shade600, size: 20.sp),
        SizedBox(width: 8.w),
        Text(
          "ช่วงเวลาที่เลือก",
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: onClearDateRange,
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(Icons.close, color: Colors.red.shade600, size: 16.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildStartDateCard() {
    // การ์ดวันที่เริ่มต้น (สีเขียว)
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today, color: Colors.green.shade600, size: 18.sp),
          SizedBox(height: 4.h),
          Text(
            "เริ่มต้น",
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            _formatDate(selectedDateRange!.start),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.green.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndDateCard() {
    // การ์ดวันที่สิ้นสุด (สีแดง)
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.shade200, width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.event, color: Colors.red.shade600, size: 18.sp),
          SizedBox(height: 4.h),
          Text(
            "สิ้นสุด",
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            _formatDate(selectedDateRange!.end),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.red.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    // ลูกศรเชื่อม
    return Icon(Icons.arrow_forward, color: Colors.blue.shade400, size: 20.sp);
  }

  String _formatDate(DateTime date) {
    // จัดรูปแบบวันที่
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }
}
