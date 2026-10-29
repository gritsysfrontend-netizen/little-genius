import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/domain/session_timer.dart';

void main() {
  test(
    'the reminder ends in the foreground and stays still in the background',
    () {
      const off = SessionClock();
      expect(off.tick(const Duration(minutes: 30)).ended, isFalse);

      final running = const SessionClock().withLimit(1);
      expect(running.tick(const Duration(seconds: 59)).ended, isFalse);
      expect(running.tick(const Duration(minutes: 1)).ended, isTrue);

      final hidden = running.background();
      expect(hidden.paused, isTrue);
      expect(hidden.tick(const Duration(minutes: 5)), hidden);

      final ended = running.tick(const Duration(minutes: 1));
      expect(ended.acknowledge().ended, isFalse);
      expect(ended.acknowledge().elapsed, Duration.zero);
      expect(ended.acknowledge().limitMinutes, 1);
    },
  );
}
