/// In-app play reminder. It advances only while the app is in the foreground.
class SessionClock {
  const SessionClock({
    this.limitMinutes,
    this.elapsed = Duration.zero,
    this.backgrounded = false,
    this.ended = false,
  });

  final int? limitMinutes;
  final Duration elapsed;
  final bool backgrounded;
  final bool ended;

  bool get enabled => limitMinutes != null && limitMinutes! > 0;

  bool get paused => enabled && backgrounded && !ended;

  SessionClock tick(Duration delta) {
    if (!enabled || ended || backgrounded || delta <= Duration.zero) {
      return this;
    }
    final next = elapsed + delta;
    final limit = Duration(minutes: limitMinutes!);
    if (next >= limit) {
      return SessionClock(
        limitMinutes: limitMinutes,
        elapsed: limit,
        backgrounded: backgrounded,
        ended: true,
      );
    }
    return SessionClock(
      limitMinutes: limitMinutes,
      elapsed: next,
      backgrounded: backgrounded,
    );
  }

  SessionClock background() {
    return SessionClock(
      limitMinutes: limitMinutes,
      elapsed: elapsed,
      backgrounded: true,
      ended: ended,
    );
  }

  SessionClock foreground() {
    return SessionClock(
      limitMinutes: limitMinutes,
      elapsed: elapsed,
      backgrounded: false,
      ended: ended,
    );
  }

  SessionClock withLimit(int? minutes) {
    return SessionClock(limitMinutes: minutes);
  }

  /// The child can go home. This does not lock the device.
  SessionClock acknowledge() {
    return SessionClock(limitMinutes: limitMinutes);
  }

  @override
  bool operator ==(Object other) {
    return other is SessionClock &&
        other.limitMinutes == limitMinutes &&
        other.elapsed == elapsed &&
        other.backgrounded == backgrounded &&
        other.ended == ended;
  }

  @override
  int get hashCode => Object.hash(limitMinutes, elapsed, backgrounded, ended);
}

const sessionLimitChoices = <int?>[null, 5, 10, 15, 20];

const sessionLimitSettingKey = 'session_limit_minutes';
