import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/content/canonical_json.dart';
import 'package:little_genius/content/lesson_parser.dart';

void main() {
  final fixture = jsonDecode(
    File('../../infrastructure/fixtures/animal.elephant.001.json')
        .readAsStringSync(),
  );
  final recorded = jsonDecode(
    File('../../infrastructure/fixtures/checksums.json').readAsStringSync(),
  );

  test(
    'the elephant fixture parses and its canonical hash matches the record',
    () {
      final parsed = parseLessonDocument(fixture);
      expect(parsed, isA<SupportedLesson>());
      final supported = parsed as SupportedLesson;
      expect(supported.document.contentId, 'animal.elephant.001');
      expect(supported.document.interaction.type, 'tap_to_learn');
      expect(
        supported.document.localizations.keys,
        containsAll(['en', 'hi', 'ta']),
      );
      expect(
        sha256Hex(utf8.encode(canonicalJson(fixture))),
        recorded['payloadSha256'],
      );
    },
  );

  test('unknown interaction, schema, and keys do not throw', () {
    expect(
      parseLessonDocument(
        _with(fixture, {
          'interaction': {'type': 'script'},
        }),
      ),
      isA<UnsupportedLesson>(),
    );
    expect(
      parseLessonDocument(_with(fixture, {'schemaVersion': '9.0'})),
      isA<UnsupportedLesson>(),
    );
    expect(
      parseLessonDocument(_with(fixture, {'html': '<b>no</b>'})),
      isA<UnsupportedLesson>(),
    );
    final nested = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
    (nested['localizations'] as Map)['en'] = {
      ...(nested['localizations'] as Map)['en'] as Map,
      'url': 'https://example.invalid',
    };
    expect(parseLessonDocument(nested), isA<UnsupportedLesson>());
    expect(parseLessonDocument('not-a-document'), isA<UnsupportedLesson>());
  });

  for (final sample in [
    ('color.red.001.json', 'single_choice', 'answer_selected'),
    ('pair.daynight.001.json', 'matching', 'all_pairs_matched'),
    ('sort.bigsmall.001.json', 'sorting', 'each_item_sorted'),
    ('count.birds.001.json', 'counting', 'count_matches'),
    ('order.morning.001.json', 'sequencing', 'order_matches'),
  ]) {
    test('${sample.$1} parses with en, hi, and ta', () {
      final document = jsonDecode(
        File('../../infrastructure/fixtures/${sample.$1}').readAsStringSync(),
      );
      final parsed = parseLessonDocument(document);
      expect(parsed, isA<SupportedLesson>());
      final supported = parsed as SupportedLesson;
      expect(supported.document.interaction.type, sample.$2);
      expect(supported.document.interaction.completionRule, sample.$3);
      expect(
        supported.document.localizations.keys,
        containsAll(['en', 'hi', 'ta']),
      );
      for (final copy in supported.document.localizations.values) {
        expect(copy.feedbackRetry, isNotNull);
      }
    });
  }

  test('an extra interaction key is not allowed', () {
    final document = jsonDecode(
      File('../../infrastructure/fixtures/color.red.001.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    (document['interaction'] as Map)['html'] = '<b>no</b>';
    expect(parseLessonDocument(document), isA<UnsupportedLesson>());
  });

  test('a choice label that drops a declared locale is not allowed', () {
    final document = jsonDecode(
      File('../../infrastructure/fixtures/color.red.001.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    final label =
        ((document['interaction'] as Map)['choices'] as List).first
            as Map<String, dynamic>;
    (label['label'] as Map).remove('ta');
    expect(parseLessonDocument(document), isA<UnsupportedLesson>());
  });
}

Object _with(Object fixture, Map<String, Object?> changes) {
  final copy = jsonDecode(jsonEncode(fixture)) as Map<String, dynamic>;
  copy.addAll(changes);
  return copy;
}
