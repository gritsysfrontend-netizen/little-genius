import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';
import '../common/page_frame.dart';

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = AppLocalizations.of(context);
    final profile = ref.watch(sessionProvider).value;
    return PageFrame(
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
          Text(text.sessionNotBuilt),
          const SizedBox(height: 8),
          Text(text.privacyNotBuilt),
          if (kIsWeb) ...[const SizedBox(height: 8), Text(text.webStorageNote)],
          if (profile != null) ...[
            const SizedBox(height: 12),
            Text(text.helloName(profile.nickname)),
          ],
          const SizedBox(height: 16),
          BigButton(
            label: text.languageSettings,
            icon: Icons.language,
            onPressed: () => context.go('/parent/language'),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: text.downloadsTitle,
            icon: Icons.download,
            onPressed: () => context.go('/parent/downloads'),
          ),
          const SizedBox(height: 12),
          BigButton(
            label: text.progressTitle,
            icon: Icons.insights,
            onPressed: () => context.go('/parent/progress'),
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
            label: text.languageEnglish,
            onPressed: () => choose('en'),
          ),
          const SizedBox(height: 12),
          BigButton(
            key: const Key('language-hi'),
            label: text.languageHindi,
            onPressed: () => choose('hi'),
          ),
          const SizedBox(height: 12),
          BigButton(
            key: const Key('language-ta'),
            label: text.languageTamil,
            onPressed: () => choose('ta'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(text.bilingualLabel),
            value: profile?.bilingualMode ?? false,
            onChanged: profile == null
                ? null
                : (value) => ref
                      .read(sessionProvider.notifier)
                      .save(profile.copyWith(bilingualMode: value)),
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
          if (_titles.isEmpty) Text(text.downloadFirst),
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
          if (_empty) Text(text.noProgress),
          for (final line in _lines) Text(line),
        ],
      ),
    );
  }
}
