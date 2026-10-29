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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(parentGateProvider.notifier).onLifecycle(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(ref.read(playbackProvider.notifier).background());
    } else if (state == AppLifecycleState.resumed) {
      ref.read(playbackProvider.notifier).foreground();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
