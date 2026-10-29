import 'dart:math' as math;

import 'package:flutter/material.dart';

double contrastRatio(Color foreground, Color background) {
  final light = math.max(_luminance(foreground), _luminance(background));
  final dark = math.min(_luminance(foreground), _luminance(background));
  return (light + 0.05) / (dark + 0.05);
}

double _luminance(Color color) {
  double channel(double value) {
    final scaled = value / 255;
    return scaled <= 0.04045
        ? scaled / 12.92
        : math.pow((scaled + 0.055) / 1.055, 2.4).toDouble();
  }

  final red = channel(color.r * 255);
  final green = channel(color.g * 255);
  final blue = channel(color.b * 255);
  return 0.2126 * red + 0.7152 * green + 0.0722 * blue;
}
