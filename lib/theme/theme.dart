import 'package:flutter/material.dart';

/// Light Color Scheme
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFF49F06), // สีหลัก
  onPrimary: Color(0xFFFFFFFF), // สีข้อความบนพื้นหลัง primary
  secondary: Color(0xFF6EAEE7), // สีรอง
  onSecondary: Color(0xFFFFFFFF), // สีข้อความบนพื้นหลัง secondary
  error: Color(0xFFBA1A1A), // สีสำหรับข้อผิดพลาด
  onError: Color(0xFFFFFFFF), // สีข้อความบนพื้นหลัง error
  surface: Color(0xFFF9FAF3), // สีพื้นหลังหลัก
  onSurface: Color(0xFF1A1C18), // สีข้อความบนพื้นหลัง surface
  shadow: Color(0xFF000000), // สีของเงา
);

/// Dark Color Scheme
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFF49F06),
  onPrimary: Color(0xFFFFFFFF),
  secondary: Color(0xFF6EAEE7),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFF1A1C18),
  onSurface: Color(0xFFF9FAF3),
  shadow: Color(0xFF000000),
);

/// Light Theme
ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightColorScheme.primary, // สีพื้นหลังปุ่ม
      foregroundColor: lightColorScheme.onPrimary, // สีข้อความบนปุ่ม
      elevation: 5.0, // ความสูงของเงาปุ่ม
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Padding
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // ขอบปุ่มโค้งมน
      ),
    ),
  ),
);

/// Dark Theme
ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
      elevation: 5.0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
);

