import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_status.dart';

class StatusMessage extends StatelessWidget {
  const StatusMessage({super.key, required this.status, this.message});

  final AppStatus status;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final body = message ?? _copy(text);
    return TickerMode(
      enabled: !reduceMotionOf(context),
      child: Semantics(
        liveRegion: _announce,
        child: Padding(
          key: Key('status-${status.name}'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(body),
        ),
      ),
    );
  }

  bool get _announce =>
      status == AppStatus.sessionEnded ||
      status == AppStatus.recoverableError ||
      status == AppStatus.downloadFailed ||
      status == AppStatus.sessionPaused;

  String _copy(AppLocalizations text) {
    return switch (status) {
      AppStatus.loading => text.stateLoading,
      AppStatus.empty => text.stateEmpty,
      AppStatus.success => text.stateSuccess,
      AppStatus.recoverableError => text.stateRecoverable,
      AppStatus.offline => text.stateOffline,
      AppStatus.retrying => text.stateRetrying,
      AppStatus.downloading => text.downloading,
      AppStatus.downloadFailed => text.downloadFailed,
      AppStatus.contentUnavailable => text.contentUnavailable,
      AppStatus.sessionPaused => text.sessionPaused,
      AppStatus.sessionEnded => text.sessionEndedBody,
      AppStatus.updateAvailable => text.stateUpdateAvailable,
    };
  }
}
