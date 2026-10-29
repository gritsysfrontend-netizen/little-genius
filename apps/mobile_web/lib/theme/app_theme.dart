import 'package:flutter/material.dart';

ThemeData appTheme() {
  const seed = Color(0xFF1F6B4A);
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    useMaterial3: true,
  );
  const fallback = ['NotoSansDevanagari', 'NotoSansTamil'];
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF6F3EA),
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
