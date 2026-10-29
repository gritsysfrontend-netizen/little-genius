import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../domain/session_timer.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';
import '../common/app_status.dart';
import '../common/page_frame.dart';
import '../common/status_message.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context);
    final profile = ref.watch(sessionProvider).value;
    return PageFrame(
      orderedFocus: true,
      onHome: () => context.go('/'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            text.parentArea,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(text.accountNotAvailable),
          const SizedBox(height: 8),
          Text(text.privacyNotBuilt),
          if (kIsWeb) ...[const SizedBox(height: 8), Text(text.webStorageNote)],
          if (profile != null) ...[
            const SizedBox(height: 12),
            Text(text.helloName(profile.nickname)),
          ],
          const SizedBox(height: 16),
          BigButton(
            key: const Key('parent-language'),
            focusOrder: 2,
            label: text.languageSettings,
            icon: Icons.language,
            onPressed: () => context.go('/parent/language'),
          ),
          const SizedBox(height: 12),
          BigButton(
            key: const Key('parent-downloads'),
            focusOrder: 3,
            label: text.downloadsTitle,
            icon: Icons.download,
            onPressed: () => context.go('/parent/downloads'),
          ),
          const SizedBox(height: 12),
          BigButton(
            key: const Key('parent-progress'),
            focusOrder: 4,
            label: text.progressTitle,
            icon: Icons.insights,
            onPressed: () => context.go('/parent/progress'),
          ),
          const SizedBox(height: 12),
          BigButton(
            key: const Key('parent-session'),
            focusOrder: 5,
            label: text.sessionLimitTitle,
            icon: Icons.timer_outlined,
            onPressed: () => context.go('/parent/session'),
          ),
        ],
      ),
    );
  }
}

class ParentLanguageScreen extends ConsumerWidget {
  const ParentLanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context);
    final profile = ref.watch(sessionProvider).value;
    Future<void> choose(String locale) async {
      ref.read(draftLocaleProvider.notifier).setLocale(locale);
      if (profile == null) return;
      await ref
          .read(sessionProvider.notifier)
          .save(profile.copyWith(preferredLocale: locale));
    }

    return PageFrame(
      orderedFocus: true,
      onBack: () => context.go('/parent'),
      onHome: () => context.go('/'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            text.chooseLanguage,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          BigButton(
            key: const Key('language-en'),
            focusOrder: 3,
            label: text.languageEnglish,
            onPressed: () => choose('en'),
          ),
          const SizedBox(height: 12),
          BigButton(
            key: const Key('language-hi'),
            focusOrder: 4,
            label: text.languageHindi,
            onPressed: () => choose('hi'),
          ),
          const SizedBox(height: 12),
          BigButton(
            key: const Key('language-ta'),
            focusOrder: 5,
            label: text.languageTamil,
            onPressed: () => choose('ta'),
          ),
          const SizedBox(height: 16),
          FocusTraversalOrder(
            order: const NumericFocusOrder(6),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(text.bilingualLabel),
              value: profile?.bilingualMode ?? false,
              onChanged: profile == null
                  ? null
                  : (value) => ref
                        .read(sessionProvider.notifier)
                        .save(profile.copyWith(bilingualMode: value)),
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  var _titles = const <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final documents = await ref.read(repositoryProvider).listDocuments();
    if (!mounted) return;
    setState(() {
      _titles = [
        for (final document in documents)
          '${document.contentId} ${document.contentVersion}',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return PageFrame(
      orderedFocus: true,
      onBack: () => context.go('/parent'),
      onHome: () => context.go('/'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            text.downloadsTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(text.accountNotAvailable),
          if (kIsWeb) ...[const SizedBox(height: 8), Text(text.webStorageNote)],
          const SizedBox(height: 12),
          if (_titles.isEmpty) ...[
            const StatusMessage(status: AppStatus.empty),
            Text(text.downloadFirst),
          ],
          for (final title in _titles) Text(title),
        ],
      ),
    );
  }
}

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  var _lines = const <String>[];
  var _empty = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = ref.read(sessionProvider).value;
    if (profile == null) return;
    final rows = await ref
        .read(repositoryProvider)
        .listProgress(profile.profileId);
    if (!mounted) return;
    final text = AppLocalizations.of(context);
    setState(() {
      _empty = rows.isEmpty;
      _lines = [
        for (final row in rows)
          '${row.categoryId}: ${text.startedLabel(row.startedCount)} ${text.completedLabel(row.completedCount)}',
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return PageFrame(
      orderedFocus: true,
      onBack: () => context.go('/parent'),
      onHome: () => context.go('/'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            text.progressTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(text.accountNotAvailable),
          const SizedBox(height: 12),
          if (_empty) ...[
            const StatusMessage(status: AppStatus.empty),
            Text(text.noProgress),
          ],
          for (final line in _lines) Text(line),
        ],
      ),
    );
  }
}

class SessionLimitScreen extends ConsumerStatefulWidget {
  const SessionLimitScreen({super.key});

  @override
  ConsumerState<SessionLimitScreen> createState() => _SessionLimitScreenState();
}

class _SessionLimitScreenState extends ConsumerState<SessionLimitScreen> {
  AppStatus? _status;

  Future<void> _choose(int? minutes) async {
    final again = _status == AppStatus.recoverableError;
    setState(() => _status = again ? AppStatus.retrying : AppStatus.loading);
    try {
      await ref.read(playReminderProvider.notifier).choose(minutes);
      if (!mounted) return;
      setState(() => _status = AppStatus.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = AppStatus.recoverableError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return PageFrame(
      orderedFocus: true,
      onBack: () => context.go('/parent'),
      onHome: () => context.go('/'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            text.sessionLimitTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(text.sessionLimitBody, key: const Key('session-limit-body')),
          const SizedBox(height: 16),
          for (final (index, minutes) in sessionLimitChoices.indexed) ...[
            BigButton(
              key: Key(minutes == null ? 'session-off' : 'session-$minutes'),
              focusOrder: 3 + index.toDouble(),
              label: minutes == null
                  ? text.sessionOff
                  : text.sessionMinutes(minutes),
              icon: Icons.timer_outlined,
              onPressed: () => _choose(minutes),
            ),
            const SizedBox(height: 12),
          ],
          if (_status != null) StatusMessage(status: _status!),
        ],
      ),
    );
  }
}
