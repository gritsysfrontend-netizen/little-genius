import 'dart:convert';

import '../../data/content_api.dart';
import '../../data/records.dart';
import '../../domain/age_band.dart';

const knownOfflineLessonId = 'animal.elephant.001';
const animalsCategoryId = 'animals';

const categoryOrder = [
  'animals',
  'colors',
  'pairs',
  'sizes',
  'numbers',
  'routines',
];

class LessonFacts {
  const LessonFacts({
    required this.contentId,
    required this.categoryId,
    required this.minMonths,
    required this.maxMonths,
    required this.locales,
    required this.titles,
  });

  final String contentId;
  final String categoryId;
  final int minMonths;
  final int maxMonths;
  final Set<String> locales;
  final Map<String, String> titles;
}

const knownLessons = <LessonFacts>[
  LessonFacts(
    contentId: 'animal.elephant.001',
    categoryId: 'animals',
    minMonths: 12,
    maxMonths: 60,
    locales: {'en', 'hi', 'ta'},
    titles: {'en': 'Elephant', 'hi': 'हाथी', 'ta': 'யானை'},
  ),
  LessonFacts(
    contentId: 'color.red.001',
    categoryId: 'colors',
    minMonths: 12,
    maxMonths: 23,
    locales: {'en', 'hi', 'ta'},
    titles: {'en': 'Red', 'hi': 'लाल', 'ta': 'சிவப்பு'},
  ),
  LessonFacts(
    contentId: 'pair.daynight.001',
    categoryId: 'pairs',
    minMonths: 25,
    maxMonths: 35,
    locales: {'en', 'hi', 'ta'},
    titles: {
      'en': 'Day and night',
      'hi': 'दिन और रात',
      'ta': 'பகல் மற்றும் இரவு',
    },
  ),
  LessonFacts(
    contentId: 'sort.bigsmall.001',
    categoryId: 'sizes',
    minMonths: 37,
    maxMonths: 47,
    locales: {'en', 'hi', 'ta'},
    titles: {
      'en': 'Big and small',
      'hi': 'बड़ा और छोटा',
      'ta': 'பெரியதும் சிறியதும்',
    },
  ),
  LessonFacts(
    contentId: 'count.birds.001',
    categoryId: 'numbers',
    minMonths: 49,
    maxMonths: 60,
    locales: {'en', 'hi', 'ta'},
    titles: {'en': 'Three birds', 'hi': 'तीन चिड़ियाँ', 'ta': 'மூன்று பறவைகள்'},
  ),
  LessonFacts(
    contentId: 'order.morning.001',
    categoryId: 'routines',
    minMonths: 37,
    maxMonths: 60,
    locales: {'en', 'hi', 'ta'},
    titles: {'en': 'Morning order', 'hi': 'सुबह का क्रम', 'ta': 'காலை வரிசை'},
  ),
];

final knownById = {for (final lesson in knownLessons) lesson.contentId: lesson};

class CatalogEntry {
  const CatalogEntry({
    required this.contentId,
    required this.title,
    required this.downloaded,
    this.contentVersion,
    this.updateAvailable = false,
  });

  final String contentId;
  final String title;
  final bool downloaded;
  final int? contentVersion;

  /// A newer published version exists. The copy already open is left as it is.
  final bool updateAvailable;
}

/// Manifest items are shown when the request succeeds and the lesson overlaps
/// the profile age band and has that locale. A missing locale is not filled
/// with English. The known lessons are offered when the request fails.
List<CatalogEntry> entriesForCategory({
  required String categoryId,
  required List<ManifestItem> manifest,
  required bool manifestFailed,
  required Map<String, StoredDocument> localById,
  String ageBand = '2-3',
  String locale = 'en',
}) {
  if (!manifestFailed) {
    return [
      for (final item in manifest)
        if (item.categoryId == categoryId &&
            _visible(item.contentId, localById, ageBand, locale, categoryId))
          CatalogEntry(
            contentId: item.contentId,
            title: _onlineTitle(item, localById[item.contentId], locale),
            contentVersion: item.contentVersion,
            downloaded: _savedCopy(localById[item.contentId], item),
            updateAvailable: _newer(localById[item.contentId], item),
          ),
    ];
  }
  final entries = <CatalogEntry>[];
  final seen = <String>{};
  for (final known in knownLessons) {
    final facts = factsFor(known.contentId, localById);
    if (facts == null || !_matches(facts, ageBand, locale, categoryId)) {
      continue;
    }
    final local = localById[known.contentId];
    entries.add(
      CatalogEntry(
        contentId: known.contentId,
        title: _payloadTitle(local?.payload, locale) ?? '',
        downloaded: local != null,
        contentVersion: local?.contentVersion,
      ),
    );
    seen.add(known.contentId);
  }
  for (final entry in localById.entries) {
    if (seen.contains(entry.key)) continue;
    final facts = factsFromPayload(entry.value.payload);
    if (facts == null || !_matches(facts, ageBand, locale, categoryId)) {
      continue;
    }
    entries.add(
      CatalogEntry(
        contentId: entry.key,
        title: _payloadTitle(entry.value.payload, locale) ?? '',
        downloaded: true,
        contentVersion: entry.value.contentVersion,
      ),
    );
  }
  return entries;
}

/// Categories that have at least one lesson for this age band and locale.
List<String> categoriesFor({
  required String ageBand,
  required String locale,
  required Map<String, StoredDocument> localById,
}) {
  final ids = <String>{};
  final seen = <String>{};
  for (final known in knownLessons) {
    final facts = factsFor(known.contentId, localById);
    if (facts != null &&
        ageOverlaps(ageBand, facts.minMonths, facts.maxMonths) &&
        facts.locales.contains(locale)) {
      ids.add(facts.categoryId);
    }
    seen.add(known.contentId);
  }
  for (final entry in localById.entries) {
    if (seen.contains(entry.key)) continue;
    final facts = factsFromPayload(entry.value.payload);
    if (facts == null) continue;
    if (ageOverlaps(ageBand, facts.minMonths, facts.maxMonths) &&
        facts.locales.contains(locale)) {
      ids.add(facts.categoryId);
    }
  }
  return [
    for (final id in categoryOrder)
      if (ids.contains(id)) id,
    for (final id in ids)
      if (!categoryOrder.contains(id)) id,
  ];
}

LessonFacts? factsFor(String contentId, Map<String, StoredDocument> localById) {
  final local = localById[contentId];
  if (local != null) {
    final parsed = factsFromPayload(local.payload);
    if (parsed != null) return parsed;
  }
  return knownById[contentId];
}

/// Reads catalog facts from a saved payload. Returns null when the payload
/// does not describe a lesson, so a placeholder `{}` keeps the known facts.
LessonFacts? factsFromPayload(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map) return null;
    final contentId = decoded['contentId'];
    final categoryId = decoded['categoryId'];
    final age = decoded['ageRange'];
    final localizations = decoded['localizations'];
    if (contentId is! String || categoryId is! String) return null;
    if (age is! Map) return null;
    final minMonths = age['minMonths'];
    final maxMonths = age['maxMonths'];
    if (minMonths is! int || maxMonths is! int) return null;
    if (localizations is! Map || localizations.isEmpty) return null;
    final locales = <String>{};
    final titles = <String, String>{};
    for (final entry in localizations.entries) {
      final code = entry.key.toString();
      if (!const {'en', 'hi', 'ta'}.contains(code)) return null;
      final copy = entry.value;
      if (copy is! Map) return null;
      final title = copy['title'];
      if (title is! String || title.isEmpty) return null;
      locales.add(code);
      titles[code] = title;
    }
    if (locales.isEmpty) return null;
    return LessonFacts(
      contentId: contentId,
      categoryId: categoryId,
      minMonths: minMonths,
      maxMonths: maxMonths,
      locales: locales,
      titles: titles,
    );
  } catch (_) {
    return null;
  }
}

bool _visible(
  String contentId,
  Map<String, StoredDocument> localById,
  String ageBand,
  String locale,
  String categoryId,
) {
  final facts = factsFor(contentId, localById);
  if (facts == null) return true;
  return _matches(facts, ageBand, locale, categoryId);
}

bool _matches(
  LessonFacts facts,
  String ageBand,
  String locale,
  String categoryId,
) {
  return facts.categoryId == categoryId &&
      ageOverlaps(ageBand, facts.minMonths, facts.maxMonths) &&
      facts.locales.contains(locale);
}

String _onlineTitle(ManifestItem item, StoredDocument? local, String locale) {
  return _payloadTitle(local?.payload, locale) ?? item.title;
}

/// Title in [locale] only. A missing localization does not fall back to English.
String? _payloadTitle(String? payload, String locale) {
  if (payload == null) return null;
  final facts = factsFromPayload(payload);
  final title = facts?.titles[locale];
  if (title == null || title.isEmpty) return null;
  return title;
}

bool _savedCopy(StoredDocument? local, ManifestItem item) {
  if (local == null) return false;
  final sameVersion =
      local.contentVersion == item.contentVersion &&
      local.payloadSha256 == item.payloadSha256;
  return sameVersion || item.contentVersion > local.contentVersion;
}

bool _newer(StoredDocument? local, ManifestItem item) {
  return local != null && item.contentVersion > local.contentVersion;
}
