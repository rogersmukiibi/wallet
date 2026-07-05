import 'package:flutter/material.dart';

final appTheme = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFF1C1E26),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFFF6B5E),
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1C1E26), elevation: 0),
);