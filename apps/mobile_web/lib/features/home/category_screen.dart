import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/lesson_parser.dart';
import '../../content/widgets.dart';
import '../../data/content_api.dart';
import '../../data/records.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';
import '../common/app_status.dart';
import '../common/page_frame.dart';
import '../common/status_message.dart';
import 'catalog.dart';
import 'category_titles.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  List<CatalogEntry> _entries = const [];
  bool _loading = true;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final profile = ref.read(sessionProvider).value;
    if (profile == null) return;
    final repository = ref.read(repositoryProvider);
    final documents = await repository.listDocuments();
    final local = <String, StoredDocument>{};
    for (final document in documents) {
      final current = local[document.contentId];
      if (current == null || document.contentVersion > current.contentVersion) {
        local[document.contentId] = document;
      }
    }
    var manifest = const <ManifestItem>[];
    var failed = false;
    try {
      manifest = await ContentApi(ref.read(byteSourceProvider))
          .manifest(locale: profile.preferredLocale, ageBand: profile.ageBand);
    } catch (_) {
      failed = true;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _offline = failed;
      _entries = entriesForCategory(
        categoryId: widget.categoryId,
        manifest: manifest,
        manifestFailed: failed,
        localById: local,
        ageBand: profile.ageBand,
        locale: profile.preferredLocale,
      );
      _entries = [
        for (final entry in _entries)
          _withLocalTitle(entry, local, profile.preferredLocale),
      ];
    });
  }

  CatalogEntry _withLocalTitle(
    CatalogEntry entry,
    Map<String, StoredDocument> local,
    String locale,
  ) {
    if (!entry.downloaded || entry.title.isNotEmpty) return entry;
    final document = local[entry.contentId];
    if (document == null) return entry;
    final parsed = parseLessonDocument(jsonDecode(document.payload));
    if (parsed is! SupportedLesson) return entry;
    final title = parsed.document.localizations[locale]?.title;
    if (title == null || title.isEmpty) return entry;
    return CatalogEntry(
      contentId: entry.contentId,
      title: title,
      downloaded: true,
      contentVersion: entry.contentVersion,
      updateAvailable: entry.updateAvailable,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final download = ref.watch(downloadProvider);
    ref.listen(downloadProvider, (previous, next) {
      if (next.phase == DownloadPhase.saved) _load();
    });
    final title = categoryLabel(text, widget.categoryId);
    return PageFrame(
      onBack: () => context.go('/'),
      onHome: () => context.go('/'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (_loading) const StatusMessage(status: AppStatus.loading),
          if (!_loading && _offline)
            const StatusMessage(status: AppStatus.offline),
          if (!_loading && !_offline && _entries.isEmpty)
            const StatusMessage(status: AppStatus.empty),
          for (final entry in _entries) ...[
            if (entry.title.isNotEmpty)
              Text(
                entry.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            if (entry.updateAvailable)
              const StatusMessage(status: AppStatus.updateAvailable),
            if (entry.downloaded)
              BigButton(
                key: Key('play-${entry.contentId}'),
                label: text.playAction,
                icon: Icons.play_arrow,
                onPressed: () => context.go('/a/${entry.contentId}'),
              )
            else
              BigButton(
                key: Key('download-${entry.contentId}'),
                label: _downloadLabel(text, download, entry.contentId),
                icon: Icons.download,
                onPressed: _busy(download, entry.contentId)
                    ? null
                    : () => ref
                          .read(downloadProvider.notifier)
                          .start(entry.contentId),
              ),
            if (_matches(download, entry.contentId)) ...[
              if (download.phase == DownloadPhase.downloading)
                const StatusMessage(status: AppStatus.downloading),
              if (download.phase == DownloadPhase.retrying)
                const StatusMessage(status: AppStatus.retrying),
              if (download.phase == DownloadPhase.failed)
                const StatusMessage(status: AppStatus.downloadFailed),
              if (download.phase == DownloadPhase.checksum)
                StatusMessage(
                  status: AppStatus.recoverableError,
                  message: text.checksumError,
                ),
              if (download.phase == DownloadPhase.saved)
                const StatusMessage(status: AppStatus.success),
              if (_busy(download, entry.contentId))
                BigButton(
                  label: text.cancel,
                  icon: Icons.close,
                  onPressed: () => ref.read(downloadProvider.notifier).cancel(),
                ),
            ],
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  bool _matches(DownloadState download, String contentId) {
    return download.contentId == contentId &&
        download.phase != DownloadPhase.idle;
  }

  bool _busy(DownloadState download, String contentId) {
    return download.contentId == contentId &&
        (download.phase == DownloadPhase.downloading ||
            download.phase == DownloadPhase.retrying);
  }

  String _downloadLabel(
    AppLocalizations text,
    DownloadState download,
    String contentId,
  ) {
    if (!_matches(download, contentId)) return text.downloadAction;
    return switch (download.phase) {
      DownloadPhase.downloading => text.downloading,
      DownloadPhase.retrying => text.stateRetrying,
      _ => text.downloadAction,
    };
  }
}
