import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.bttncolor,
  });
  final String label;
  final Color? bttncolor;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bttncolor, // Set the background color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // Set the border radius
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white, // Set text color to white
          ),
        ),
      ),
    );
  }
}
