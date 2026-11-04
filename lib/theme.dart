import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const ink = Color(0xFF182D49);
const muted = Color(0xFF5C6F88);
const blue = Color(0xFF245BCC);
const canvas = Color(0xFFF3F7FC);
const line = Color(0xFFDFE7F2);

String money(int amount) =>
    '${NumberFormat.decimalPattern('vi_VN').format(amount)} đ';
String displayDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: blue,
    brightness: Brightness.light,
  ).copyWith(primary: blue, surface: Colors.white, onSurface: ink);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'BeVietnamPro',
    scaffoldBackgroundColor: canvas,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: ink, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'BeVietnamPro',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: blue, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: line, thickness: 1),
  );
}

(Color, IconData) categoryStyle(String category) => switch (category) {
  'Ăn uống' => (const Color(0xFFAC4C18), Icons.restaurant_rounded),
  'Đi lại' => (const Color(0xFF245BCC), Icons.directions_bus_rounded),
  'Học tập' => (const Color(0xFF6D45AA), Icons.menu_book_rounded),
  'Giải trí' => (const Color(0xFF137C68), Icons.sports_esports_rounded),
  _ => (const Color(0xFF5C6F88), Icons.more_horiz_rounded),
};
