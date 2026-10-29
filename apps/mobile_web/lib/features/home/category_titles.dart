import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'catalog.dart';

String categoryLabel(AppLocalizations text, String categoryId) {
  return switch (categoryId) {
    animalsCategoryId => text.animalsTitle,
    'colors' => text.colorsTitle,
    'pairs' => text.pairsTitle,
    'sizes' => text.sizesTitle,
    'numbers' => text.numbersTitle,
    'routines' => text.routinesTitle,
    _ => categoryId,
  };
}

IconData categoryIcon(String categoryId) {
  return switch (categoryId) {
    'animals' => Icons.pets,
    'colors' => Icons.palette,
    'pairs' => Icons.join_inner,
    'sizes' => Icons.straighten,
    'numbers' => Icons.pin,
    'routines' => Icons.wb_sunny,
    _ => Icons.circle,
  };
}
