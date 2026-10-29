/// Hand-written interaction union. The lesson parser is the allowlist:
/// unknown keys, unknown types, and broken rules become null here, and the
/// parser turns that into [UnsupportedLesson] without throwing.
sealed class LessonInteraction {
  const LessonInteraction();

  String get type;
  String get completionRule;
  String get retryPolicy;

  Map<String, dynamic> toJson();
}

class TapToLearn extends LessonInteraction {
  const TapToLearn({required this.targetAssetId});

  final String targetAssetId;

  @override
  String get type => 'tap_to_learn';

  @override
  String get completionRule => 'target_tapped';

  @override
  String get retryPolicy => 'unlimited';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'targetAssetId': targetAssetId,
    'completionRule': completionRule,
    'retryPolicy': retryPolicy,
  };
}

class SingleChoice extends LessonInteraction {
  const SingleChoice({required this.answerId, required this.choices});

  final String answerId;
  final List<LabeledChoice> choices;

  @override
  String get type => 'single_choice';

  @override
  String get completionRule => 'answer_selected';

  @override
  String get retryPolicy => 'unlimited';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'completionRule': completionRule,
    'retryPolicy': retryPolicy,
    'answerId': answerId,
    'choices': [for (final choice in choices) choice.toJson()],
  };
}

class MatchingPairs extends LessonInteraction {
  const MatchingPairs({required this.pairs});

  final List<MatchPair> pairs;

  @override
  String get type => 'matching';

  @override
  String get completionRule => 'all_pairs_matched';

  @override
  String get retryPolicy => 'unlimited';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'completionRule': completionRule,
    'retryPolicy': retryPolicy,
    'pairs': [for (final pair in pairs) pair.toJson()],
  };
}

class SortingActivity extends LessonInteraction {
  const SortingActivity({required this.bins, required this.items});

  final List<LabeledChoice> bins;
  final List<SortItem> items;

  @override
  String get type => 'sorting';

  @override
  String get completionRule => 'each_item_sorted';

  @override
  String get retryPolicy => 'unlimited';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'completionRule': completionRule,
    'retryPolicy': retryPolicy,
    'bins': [for (final bin in bins) bin.toJson()],
    'items': [for (final item in items) item.toJson()],
  };
}

class CountingActivity extends LessonInteraction {
  const CountingActivity({required this.targetCount, required this.maxCount});

  final int targetCount;
  final int maxCount;

  @override
  String get type => 'counting';

  @override
  String get completionRule => 'count_matches';

  @override
  String get retryPolicy => 'unlimited';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'completionRule': completionRule,
    'retryPolicy': retryPolicy,
    'targetCount': targetCount,
    'maxCount': maxCount,
  };
}

class SequencingActivity extends LessonInteraction {
  const SequencingActivity({required this.steps});

  final List<LabeledChoice> steps;

  @override
  String get type => 'sequencing';

  @override
  String get completionRule => 'order_matches';

  @override
  String get retryPolicy => 'unlimited';

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'completionRule': completionRule,
    'retryPolicy': retryPolicy,
    'steps': [for (final step in steps) step.toJson()],
  };
}

class LabeledChoice {
  const LabeledChoice({required this.id, required this.label});

  final String id;
  final LocaleLabel label;

  Map<String, dynamic> toJson() => {'id': id, 'label': label.toJson()};
}

class MatchPair {
  const MatchPair({
    required this.id,
    required this.prompt,
    required this.match,
  });

  final String id;
  final LocaleLabel prompt;
  final LocaleLabel match;

  Map<String, dynamic> toJson() => {
    'id': id,
    'prompt': prompt.toJson(),
    'match': match.toJson(),
  };
}

class SortItem {
  const SortItem({required this.id, required this.label, required this.binId});

  final String id;
  final LocaleLabel label;
  final String binId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label.toJson(),
    'binId': binId,
  };
}

class LocaleLabel {
  const LocaleLabel(this.byLocale);

  final Map<String, String> byLocale;

  /// The string for [locale], or null when that localization is absent.
  /// Callers must not substitute English.
  String? forLocale(String locale) {
    final value = byLocale[locale];
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Map<String, String> toJson() => Map<String, String>.from(byLocale);
}

final _idPattern = RegExp(r'^[a-z0-9._-]{1,80}$');

/// [requiredLocales] is the set of locales the document declares.
/// When it is null, label coverage is not checked (used by JSON decoding
/// after the parser has already accepted the document).
LessonInteraction? tryParseInteraction(
  Object? raw, {
  Set<String>? requiredLocales,
}) {
  final json = _asMap(raw);
  if (json == null) return null;
  final type = json['type'];
  if (json['retryPolicy'] != 'unlimited') return null;
  return switch (type) {
    'tap_to_learn' => _tap(json),
    'single_choice' => _singleChoice(json, requiredLocales),
    'matching' => _matching(json, requiredLocales),
    'sorting' => _sorting(json, requiredLocales),
    'counting' => _counting(json),
    'sequencing' => _sequencing(json, requiredLocales),
    _ => null,
  };
}

LessonInteraction readInteraction(Object? json) {
  final parsed = tryParseInteraction(json);
  if (parsed == null) {
    throw const FormatException('interaction');
  }
  return parsed;
}

Map<String, dynamic> writeInteraction(LessonInteraction value) =>
    value.toJson();

TapToLearn? _tap(Map<String, dynamic> json) {
  if (!_keys(json, {
    'type',
    'targetAssetId',
    'completionRule',
    'retryPolicy',
  })) {
    return null;
  }
  if (json['completionRule'] != 'target_tapped') return null;
  if (!_isId(json['targetAssetId'])) return null;
  return TapToLearn(targetAssetId: json['targetAssetId'] as String);
}

SingleChoice? _singleChoice(Map<String, dynamic> json, Set<String>? locales) {
  if (!_keys(json, {
    'type',
    'completionRule',
    'retryPolicy',
    'answerId',
    'choices',
  })) {
    return null;
  }
  if (json['completionRule'] != 'answer_selected') return null;
  if (!_isId(json['answerId'])) return null;
  final choices = _choices(json['choices'], locales, min: 2, max: 4);
  if (choices == null) return null;
  final answerId = json['answerId'] as String;
  if (!choices.any((choice) => choice.id == answerId)) return null;
  return SingleChoice(answerId: answerId, choices: choices);
}

MatchingPairs? _matching(Map<String, dynamic> json, Set<String>? locales) {
  if (!_keys(json, {'type', 'completionRule', 'retryPolicy', 'pairs'})) {
    return null;
  }
  if (json['completionRule'] != 'all_pairs_matched') return null;
  final rawPairs = json['pairs'];
  if (rawPairs is! List || rawPairs.length < 2 || rawPairs.length > 4) {
    return null;
  }
  final pairs = <MatchPair>[];
  final ids = <String>{};
  for (final raw in rawPairs) {
    final pair = _asMap(raw);
    if (pair == null || !_keys(pair, {'id', 'prompt', 'match'})) return null;
    if (!_isId(pair['id']) || !ids.add(pair['id'] as String)) return null;
    final prompt = _label(pair['prompt'], locales);
    final match = _label(pair['match'], locales);
    if (prompt == null || match == null) return null;
    pairs.add(
      MatchPair(id: pair['id'] as String, prompt: prompt, match: match),
    );
  }
  return MatchingPairs(pairs: pairs);
}

SortingActivity? _sorting(Map<String, dynamic> json, Set<String>? locales) {
  if (!_keys(json, {
    'type',
    'completionRule',
    'retryPolicy',
    'bins',
    'items',
  })) {
    return null;
  }
  if (json['completionRule'] != 'each_item_sorted') return null;
  final bins = _choices(json['bins'], locales, min: 2, max: 3);
  if (bins == null) return null;
  final binIds = {for (final bin in bins) bin.id};
  final rawItems = json['items'];
  if (rawItems is! List || rawItems.length < 2 || rawItems.length > 4) {
    return null;
  }
  final items = <SortItem>[];
  final ids = <String>{};
  for (final raw in rawItems) {
    final item = _asMap(raw);
    if (item == null || !_keys(item, {'id', 'label', 'binId'})) return null;
    if (!_isId(item['id']) || !ids.add(item['id'] as String)) return null;
    if (!_isId(item['binId']) || !binIds.contains(item['binId'])) return null;
    final label = _label(item['label'], locales);
    if (label == null) return null;
    items.add(
      SortItem(
        id: item['id'] as String,
        label: label,
        binId: item['binId'] as String,
      ),
    );
  }
  return SortingActivity(bins: bins, items: items);
}

CountingActivity? _counting(Map<String, dynamic> json) {
  if (!_keys(json, {
    'type',
    'completionRule',
    'retryPolicy',
    'targetCount',
    'maxCount',
  })) {
    return null;
  }
  if (json['completionRule'] != 'count_matches') return null;
  final target = json['targetCount'];
  final max = json['maxCount'];
  if (target is! int || max is! int) return null;
  if (target < 1 || target > 10 || max < 1 || max > 10) return null;
  if (max < target) return null;
  return CountingActivity(targetCount: target, maxCount: max);
}

SequencingActivity? _sequencing(
  Map<String, dynamic> json,
  Set<String>? locales,
) {
  if (!_keys(json, {'type', 'completionRule', 'retryPolicy', 'steps'})) {
    return null;
  }
  if (json['completionRule'] != 'order_matches') return null;
  final steps = _choices(json['steps'], locales, min: 2, max: 6);
  if (steps == null) return null;
  return SequencingActivity(steps: steps);
}

List<LabeledChoice>? _choices(
  Object? raw,
  Set<String>? locales, {
  required int min,
  required int max,
}) {
  if (raw is! List || raw.length < min || raw.length > max) return null;
  final choices = <LabeledChoice>[];
  final ids = <String>{};
  for (final item in raw) {
    final choice = _asMap(item);
    if (choice == null || !_keys(choice, {'id', 'label'})) return null;
    if (!_isId(choice['id']) || !ids.add(choice['id'] as String)) return null;
    final label = _label(choice['label'], locales);
    if (label == null) return null;
    choices.add(LabeledChoice(id: choice['id'] as String, label: label));
  }
  return choices;
}

LocaleLabel? _label(Object? raw, Set<String>? requiredLocales) {
  final json = _asMap(raw);
  if (json == null || json.isEmpty) return null;
  if (!_keys(json, {'en', 'hi', 'ta'})) return null;
  final values = <String, String>{};
  for (final entry in json.entries) {
    final text = entry.value;
    if (text is! String || text.isEmpty || text.length > 40) return null;
    values[entry.key] = text;
  }
  if (requiredLocales != null) {
    for (final code in requiredLocales) {
      if (!values.containsKey(code)) return null;
    }
  }
  return LocaleLabel(values);
}

Map<String, dynamic>? _asMap(Object? raw) {
  if (raw is! Map) return null;
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

bool _keys(Map<String, dynamic> value, Set<String> allowed) {
  return value.keys.every(allowed.contains);
}

bool _isId(Object? value) => value is String && _idPattern.hasMatch(value);
