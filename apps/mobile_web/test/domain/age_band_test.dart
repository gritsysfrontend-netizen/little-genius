import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/domain/age_band.dart';

void main() {
  test('age bands overlap inclusively and do not invent a range', () {
    expect(monthsForBand('1-2'), (min: 12, max: 24));
    expect(monthsForBand('2-3'), (min: 24, max: 36));
    expect(monthsForBand('3-4'), (min: 36, max: 48));
    expect(monthsForBand('4-5'), (min: 48, max: 60));
    expect(ageOverlaps('1-2', 12, 60), isTrue);
    expect(ageOverlaps('4-5', 12, 60), isTrue);
    expect(ageOverlaps('1-2', 24, 24), isTrue);
    expect(ageOverlaps('2-3', 24, 24), isTrue);
    expect(ageOverlaps('3-4', 24, 24), isFalse);
    expect(ageOverlaps('1-2', 61, 70), isFalse);
    expect(ageOverlaps('unknown', 12, 60), isFalse);
  });
}
