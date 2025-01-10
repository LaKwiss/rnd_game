import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color.fromARGB(255, 0, 0, 255);
  static const Color white = Colors.white;
  static const double borderRadius = 12.0;
  static const double padding = 24.0;
  static const Color whiteTransparent = Colors.white70;

  static TextStyle titleStyle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle labelStyle = TextStyle(
    color: Colors.grey[700],
    fontWeight: FontWeight.w500,
  );

  static TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static TextStyle switchButtonTextStyle = TextStyle(
    fontSize: 14,
    color: primaryColor,
    fontWeight: FontWeight.w600,
  );

  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
    );
  }
}
