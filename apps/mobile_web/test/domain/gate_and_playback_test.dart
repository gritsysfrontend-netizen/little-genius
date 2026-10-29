import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:little_genius/domain/gate_policy.dart';
import 'package:little_genius/domain/playback.dart';

void main() {
  final start = DateTime.utc(2026, 10, 29, 12);

  test('background longer than a minute locks the gate', () {
    final hidden = advanceGate(
      unlocked: true,
      hiddenAt: null,
      lifecycle: AppLifecycleState.paused,
      now: start,
    );
    expect(hidden.unlocked, isTrue);
    expect(hidden.hiddenAt, start);

    final inactive = advanceGate(
      unlocked: true,
      hiddenAt: start,
      lifecycle: AppLifecycleState.inactive,
      now: start.add(const Duration(minutes: 2)),
    );
    expect(inactive.unlocked, isTrue);
    expect(inactive.hiddenAt, start);

    final brief = advanceGate(
      unlocked: true,
      hiddenAt: start,
      lifecycle: AppLifecycleState.resumed,
      now: start.add(const Duration(seconds: 30)),
    );
    expect(brief.unlocked, isTrue);
    expect(brief.hiddenAt, isNull);

    final away = advanceGate(
      unlocked: true,
      hiddenAt: start,
      lifecycle: AppLifecycleState.resumed,
      now: start.add(const Duration(minutes: 1, seconds: 1)),
    );
    expect(away.unlocked, isFalse);
  });

  test('playback pauses in the background and does not resume by itself', () {
    const idle = Playback();
    final playing = idle.userPlay();
    expect(playing.playing, isTrue);
    final background = playing.background();
    expect(background.playing, isFalse);
    expect(background.waitingForTap, isTrue);
    expect(background.resumeOnForeground, isFalse);
    expect(idle.background().waitingForTap, isFalse);
  });
}
