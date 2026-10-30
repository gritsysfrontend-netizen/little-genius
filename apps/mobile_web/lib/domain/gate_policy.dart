import 'package:flutter/widgets.dart';

class GateSnapshot {
  const GateSnapshot({required this.unlocked, required this.hiddenAt});

  final bool unlocked;
  final DateTime? hiddenAt;
}

/// The gate stays unlocked across a short interruption.
/// Leaving the foreground for more than a minute locks it again.
/// `inactive` does not start or clear that timer.
GateSnapshot advanceGate({
  required bool unlocked,
  required DateTime? hiddenAt,
  required AppLifecycleState lifecycle,
  required DateTime now,
}) {
  switch (lifecycle) {
    case AppLifecycleState.paused:
    case AppLifecycleState.hidden:
    case AppLifecycleState.detached:
      return GateSnapshot(unlocked: unlocked, hiddenAt: hiddenAt ?? now);
    case AppLifecycleState.resumed:
      if (hiddenAt != null &&
          now.difference(hiddenAt) > const Duration(minutes: 1)) {
        return const GateSnapshot(unlocked: false, hiddenAt: null);
      }
      return GateSnapshot(unlocked: unlocked, hiddenAt: null);
    case AppLifecycleState.inactive:
      return GateSnapshot(unlocked: unlocked, hiddenAt: hiddenAt);
  }
}
