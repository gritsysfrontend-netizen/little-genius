import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/widgets.dart';
import '../../data/content_api.dart';
import '../../data/downloader.dart';
import '../../domain/content_pack.dart';
import '../../domain/session_timer.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';
import '../common/app_status.dart';
import '../common/page_frame.dart';
import '../common/status_message.dart';
import '../home/category_titles.dart';
import 'download_manager.dart';
import 'local_progress.dart';

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
  DownloadManagerSnapshot? _snapshot;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repository = ref.read(repositoryProvider);
    final documents = await repository.listDocuments();
    final storage = await repository.storageUsedBytes();
    final installed = await repository.getSetting(publishedPackSettingKey);
    String? fetched;
    var failed = false;
    try {
      final bytes = await ref
          .read(byteSourceProvider)
          .get(
            Uri.parse('$apiBaseUrl/api/v1/content/packs/$catalogPackId'),
            DownloadCancelToken(),
          );
      fetched = utf8.decode(bytes);
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _snapshot = describeDownloads(
        storageBytes: storage,
        installedJson: installed,
        fetchedJson: fetched,
        fetchFailed: failed,
        documents: documents,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final download = ref.watch(downloadProvider);
    ref.listen(downloadProvider, (previous, next) {
      if (next.phase == DownloadPhase.saved) _load();
    });
    final snapshot = _snapshot;
    final busy =
        download.contentId == catalogPackId &&
        (download.phase == DownloadPhase.downloading ||
            download.phase == DownloadPhase.retrying);
    final failedPack =
        download.contentId == catalogPackId &&
        (download.phase == DownloadPhase.failed ||
            download.phase == DownloadPhase.checksum);
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
          if (_loading) const StatusMessage(status: AppStatus.loading),
          if (snapshot != null) ...[
            Text(
              text.storageUsed(snapshot.storageBytes),
              key: const Key('storage-used'),
            ),
            if (snapshot.installedPackVersion != null)
              Text(
                text.installedPack(snapshot.installedPackVersion!),
                key: const Key('installed-pack'),
              ),
            if (snapshot.offline)
              const StatusMessage(status: AppStatus.offline),
            if (snapshot.checksumRejected)
              StatusMessage(
                status: AppStatus.recoverableError,
                message: text.packCheckFailed,
              ),
            if (download.phase == DownloadPhase.downloading &&
                download.contentId == catalogPackId)
              const StatusMessage(status: AppStatus.downloading),
            if (download.phase == DownloadPhase.retrying &&
                download.contentId == catalogPackId)
              const StatusMessage(status: AppStatus.retrying),
            if (download.phase == DownloadPhase.failed &&
                download.contentId == catalogPackId)
              const StatusMessage(status: AppStatus.downloadFailed),
            if (download.phase == DownloadPhase.checksum &&
                download.contentId == catalogPackId)
              StatusMessage(
                status: AppStatus.recoverableError,
                message: text.checksumError,
              ),
            const SizedBox(height: 12),
            for (final lesson in snapshot.lessons) ...[
              Text(lesson.contentId),
              Text(
                lesson.downloaded ? text.downloadedCopy : text.notDownloaded,
                key: Key(
                  lesson.downloaded
                      ? 'downloaded-${lesson.contentId}'
                      : 'not-downloaded-${lesson.contentId}',
                ),
              ),
              const SizedBox(height: 8),
            ],
            BigButton(
              key: const Key('download-pack'),
              focusOrder: 3,
              label: failedPack ? text.retry : text.downloadPack,
              icon: Icons.download,
              onPressed: busy
                  ? null
                  : () => ref
                        .read(downloadProvider.notifier)
                        .startPack(catalogPackId),
            ),
            if (busy) ...[
              const SizedBox(height: 12),
              BigButton(
                key: const Key('cancel-pack'),
                focusOrder: 4,
                label: text.cancel,
                icon: Icons.close,
                onPressed: () => ref.read(downloadProvider.notifier).cancel(),
              ),
            ],
          ],
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
  LocalProgressView? _view;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = await ref.read(sessionProvider.future);
    if (!mounted) return;
    if (profile == null) {
      setState(() => _loaded = true);
      return;
    }
    final repository = ref.read(repositoryProvider);
    final events = await repository.listEvents(profile.profileId);
    final summaries = await repository.listProgress(profile.profileId);
    if (!mounted) return;
    setState(() {
      _loaded = true;
      _view = describeLocalProgress(
        ageBand: profile.ageBand,
        locale: profile.preferredLocale,
        events: events,
        summaries: summaries,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final view = _view;
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
          const SizedBox(height: 8),
          Text(text.progressOnDevice, key: const Key('progress-on-device')),
          if (!_loaded) ...[
            const SizedBox(height: 12),
            const StatusMessage(status: AppStatus.loading),
          ],
          if (view != null) ...[
            const SizedBox(height: 20),
            Text(
              text.completedHeading,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (view.completed.isEmpty)
              Text(text.noProgress, key: const Key('no-progress'))
            else
              for (final item in view.completed)
                Text(item.label, key: Key('completed-${item.contentId}')),
            const SizedBox(height: 20),
            Text(
              text.categoriesHeading,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (view.categoriesTouched.isEmpty)
              Text(text.noCategoryYet, key: const Key('no-categories'))
            else
              for (final categoryId in view.categoriesTouched)
                Text(
                  categoryLabel(text, categoryId),
                  key: Key('category-touched-$categoryId'),
                ),
            const SizedBox(height: 20),
            Text(
              text.recentHeading,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (view.recent.isEmpty)
              Text(text.noRecent, key: const Key('no-recent'))
            else
              for (final item in view.recent)
                Text(
                  '${item.label} · ${item.eventType == 'completed' ? text.finished : text.openedActivity}',
                  key: Key('recent-${item.eventId}'),
                ),
            const SizedBox(height: 20),
            Text(
              text.suggestionHeading,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (view.suggestion == null)
              Text(text.suggestionNone, key: const Key('no-suggestion'))
            else
              Text(
                view.suggestion!.label,
                key: Key('suggestion-${view.suggestion!.contentId}'),
              ),
          ],
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
