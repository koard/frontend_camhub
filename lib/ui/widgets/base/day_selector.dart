import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DaySelector extends StatelessWidget {
  final String selectedDay;
  final List<String> days;
  final ValueChanged<String> onChanged;

  const DaySelector({
    super.key,
    required this.selectedDay,
    required this.days,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "เลือกวัน",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        ),
        value: selectedDay,
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
        items:
            days
                .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                .toList(),
      ),
    );
  }
}
