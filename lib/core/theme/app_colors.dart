import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (matching React design)
  static const Color primary = Color(0xFF2E8B57); // Sea Green
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  
  // Secondary Colors
  static const Color secondary = Color(0xFF03DAC6);
  static const Color secondaryLight = Color(0xFF66FFF9);
  static const Color secondaryDark = Color(0xFF00A896);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color surfaceVariant = Color(0xFFE8F5E8);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  
  // Status Colors (matching silo temperature thresholds)
  static const Color success = Color(0xFF4CAF50); // Green - Normal (<30°C)
  static const Color warning = Color(0xFFFFC107); // Yellow - Warning (30-40°C)
  static const Color error = Color(0xFFF44336);   // Red - Critical (>40°C)
  static const Color info = Color(0xFF2196F3);
  static const Color disabled = Color(0xFF9E9E9E); // Gray - Disconnected (-127°C)
  
  // Silo Status Colors
  static const Color siloNormal = Color(0xFF4CAF50);
  static const Color siloWarning = Color(0xFFFFC107);
  static const Color siloCritical = Color(0xFFF44336);
  static const Color siloDisconnected = Color(0xFF9E9E9E);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF388E3C)],
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, Color(0xFFF57C00)],
  );
  
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [error, Color(0xFFD32F2F)],
  );
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF2E8B57),
    Color(0xFF4CAF50),
    Color(0xFF81C784),
    Color(0xFFA5D6A7),
    Color(0xFFC8E6C9),
    Color(0xFF03DAC6),
    Color(0xFF26A69A),
    Color(0xFF4DB6AC),
  ];
  
  // Shadow Colors
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowMedium = Colors.black.withOpacity(0.12);
  static Color shadowDark = Colors.black.withOpacity(0.16);
  
  // Overlay Colors
  static Color overlay = Colors.black.withOpacity(0.5);
  static Color overlayLight = Colors.black.withOpacity(0.3);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderDark = Color(0xFFBDBDBD);
}
