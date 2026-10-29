import 'package:flutter/material.dart';

ThemeData appTheme() {
  const seed = Color(0xFF1F6B4A);
  const paper = Color(0xFFF6F3EA);
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      primary: seed,
      onPrimary: Colors.white,
      surface: paper,
      onSurface: const Color(0xFF1C1B19),
    ),
    useMaterial3: true,
  );
  const fallback = ['NotoSansDevanagari', 'NotoSansTamil'];
  return base.copyWith(
    scaffoldBackgroundColor: paper,
    textTheme: base.textTheme.apply(
      fontFamily: 'NotoSans',
      fontFamilyFallback: fallback,
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: 'NotoSans',
      fontFamilyFallback: fallback,
    ),
  );
}
