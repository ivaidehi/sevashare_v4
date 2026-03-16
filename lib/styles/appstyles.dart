import 'dart:ui';

import 'package:flutter/material.dart';

class AppStyles {

  // Colors
  static Color primaryColor = const Color(0xFF1F4369);
  static Color primaryColor_light = const Color(0x331F4369);
  static Color secondaryColor = const Color(0xFF4EA59B);
  static Color bgColor = Color(0xFFFEF7FF);

  // Gradients
  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryColor, // You don't need the 'AppStyles.' prefix when inside the same class!
      secondaryColor,
    ],
  );

  // TextStyles
  static TextStyle headLineStyle = TextStyle(
    fontSize: 30, fontWeight: FontWeight.bold, color: secondaryColor,);
  static TextStyle subHeadLineStyle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor,);


  // ButtonStyles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: secondaryColor,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 0,
  );

  static ButtonStyle outLinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: secondaryColor,
    side: BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}