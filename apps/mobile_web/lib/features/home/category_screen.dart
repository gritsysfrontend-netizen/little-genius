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
import '../common/page_frame.dart';
import 'catalog.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  List<CatalogEntry> _entries = const [];
  bool _loading = true;

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
      _entries = entriesForCategory(
        categoryId: widget.categoryId,
        manifest: manifest,
        manifestFailed: failed,
        localById: local,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final download = ref.watch(downloadProvider);
    ref.listen(downloadProvider, (previous, next) {
      if (next.phase == DownloadPhase.saved) _load();
    });
    final title = widget.categoryId == animalsCategoryId
        ? text.animalsTitle
        : widget.categoryId;
    return PageFrame(
      onBack: () => context.go('/'),
      onHome: () => context.go('/'),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (_loading) Text(text.downloading),
          if (!_loading && _entries.isEmpty) Text(text.contentUnavailable),
          for (final entry in _entries) ...[
            if (entry.title.isNotEmpty)
              Text(
                entry.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
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
                label:
                    download.phase == DownloadPhase.downloading &&
                        download.contentId == entry.contentId
                    ? text.downloading
                    : text.downloadAction,
                icon: Icons.download,
                onPressed: download.phase == DownloadPhase.downloading
                    ? null
                    : () => ref
                          .read(downloadProvider.notifier)
                          .start(entry.contentId),
              ),
            if (download.contentId == entry.contentId &&
                download.phase == DownloadPhase.downloading)
              BigButton(
                label: text.cancel,
                icon: Icons.close,
                onPressed: () => ref.read(downloadProvider.notifier).cancel(),
              ),
            if (download.contentId == entry.contentId &&
                download.phase == DownloadPhase.failed)
              Text(text.downloadFailed),
            if (download.contentId == entry.contentId &&
                download.phase == DownloadPhase.checksum)
              Text(text.checksumError),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
