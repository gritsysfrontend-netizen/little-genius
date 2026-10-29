import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';
import 'routing/providers.dart';
import 'theme/app_theme.dart';

class LittleGeniusApp extends ConsumerWidget {
  const LittleGeniusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final profile = ref.watch(sessionProvider).value;
    final draft = ref.watch(draftLocaleProvider);
    final code = profile?.preferredLocale ?? draft;
    return _LifecycleBinder(
      child: MaterialApp.router(
        title: 'Little Genius',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        locale: Locale(code),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
        builder: (context, child) => _PausedBanner(child: child),
      ),
    );
  }
}

class _LifecycleBinder extends ConsumerStatefulWidget {
  const _LifecycleBinder({required this.child});

  final Widget child;

  @override
  ConsumerState<_LifecycleBinder> createState() => _LifecycleBinderState();
}

class _LifecycleBinderState extends ConsumerState<_LifecycleBinder>
    with WidgetsBindingObserver {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.listenManual(playReminderProvider, (_, _) => _syncTicker());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncTicker();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncTicker() {
    final clock = ref.read(playReminderProvider);
    final run = clock.enabled && !clock.ended && !clock.backgrounded;
    if (run) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        ref
            .read(playReminderProvider.notifier)
            .tick(const Duration(seconds: 1));
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(parentGateProvider.notifier).onLifecycle(state);
    final reminder = ref.read(playReminderProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      reminder.background();
      unawaited(ref.read(playbackProvider.notifier).background());
    } else if (state == AppLifecycleState.resumed) {
      reminder.foreground();
      ref.read(playbackProvider.notifier).foreground();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PausedBanner extends ConsumerWidget {
  const _PausedBanner({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = ref.watch(playReminderProvider).paused;
    final body = child ?? const SizedBox.shrink();
    if (!paused) return body;
    final text = AppLocalizations.of(context);
    return Column(
      children: [
        Semantics(
          liveRegion: true,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: SafeArea(
              bottom: false,
              child: Padding(
                key: const Key('session-paused'),
                padding: const EdgeInsets.all(12),
                child: Text(text.sessionPaused),
              ),
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
