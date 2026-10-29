import 'package:flutter/widgets.dart';

enum AppStatus {
  loading,
  empty,
  success,
  recoverableError,
  offline,
  retrying,
  downloading,
  downloadFailed,
  contentUnavailable,
  sessionPaused,
  sessionEnded,
  updateAvailable,
}

/// Parent screens stay still when the platform asks for reduced motion.
bool reduceMotionOf(BuildContext context) {
  final media = MediaQuery.of(context);
  return media.disableAnimations || media.accessibleNavigation;
}
