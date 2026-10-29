const ageBands = ['1-2', '2-3', '3-4', '4-5'];

({int min, int max}) monthsForBand(String band) {
  return switch (band) {
    '1-2' => (min: 12, max: 24),
    '2-3' => (min: 24, max: 36),
    '3-4' => (min: 36, max: 48),
    '4-5' => (min: 48, max: 60),
    _ => (min: 0, max: 0),
  };
}

bool ageOverlaps(String band, int minMonths, int maxMonths) {
  final range = monthsForBand(band);
  if (range.min == 0) return false;
  return minMonths <= range.max && maxMonths >= range.min;
}
