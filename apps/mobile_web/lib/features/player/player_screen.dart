import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/canonical_json.dart';
import '../../content/lesson_document.dart';
import '../../content/lesson_parser.dart';
import '../../content/media_type.dart';
import '../../content/widgets.dart';
import '../../domain/ids.dart';
import '../../domain/locale_copy.dart';
import '../../domain/progress_rules.dart';
import '../../l10n/app_localizations.dart';
import '../../routing/providers.dart';
import '../common/page_frame.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.contentId});

  final String contentId;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  _PlayerKind _kind = _PlayerKind.loading;
  ParsedLesson? _lesson;
  ResolvedCopy? _copy;
  Uint8List? _image;
  String _imageLabel = '';
  String? _feedback;
  bool _audioMissing = false;
  bool _playedIntro = false;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repository = ref.read(repositoryProvider);
    final profile = ref.read(sessionProvider).value;
    final document = await repository.latestDocument(widget.contentId);
    if (!mounted) return;
    if (document == null || profile == null) {
      setState(() => _kind = _PlayerKind.missing);
      return;
    }
    if (sha256Hex(utf8.encode(document.payload)) != document.payloadSha256) {
      setState(() => _kind = _PlayerKind.checksum);
      return;
    }
    final parsed = parseLessonDocument(jsonDecode(document.payload));
    if (parsed is! SupportedLesson) {
      setState(() {
        _lesson = parsed;
        _kind = _PlayerKind.ready;
      });
      return;
    }
    final lesson = parsed.document;
    Uint8List? image;
    for (final asset in lesson.assets) {
      final blob = await repository.getBlob(asset.assetId);
      if (blob == null ||
          sha256Hex(blob.bytes) != asset.sha256 ||
          blob.sha256 != asset.sha256) {
        if (mounted) setState(() => _kind = _PlayerKind.checksum);
        return;
      }
      if (asset.assetId == lesson.interaction.targetAssetId) image = blob.bytes;
    }
    final copy = resolveCopy(
      localizations: {
        for (final entry in lesson.localizations.entries)
          entry.key: _copyOf(entry.value),
      },
      locale: profile.preferredLocale,
      bilingual: profile.bilingualMode,
    );
    if (!mounted) return;
    if (copy == null) {
      setState(() {
        _lesson = const UnsupportedLesson('locale');
        _kind = _PlayerKind.ready;
      });
      return;
    }
    setState(() {
      _lesson = parsed;
      _copy = copy;
      _image = image;
      _imageLabel =
          lesson.accessibility.imageLabel[copy.primaryLocale] ??
          copy.primary.title;
      _kind = _PlayerKind.ready;
      _startedAt = DateTime.now().toUtc();
    });
    await repository.applyEvent(
      profileId: profile.profileId,
      categoryId: lesson.categoryId,
      event: LearningEvent(
        eventId: uuidV4(),
        contentId: lesson.contentId,
        contentVersion: lesson.contentVersion,
        eventType: 'started',
        occurredAt: _startedAt!,
      ),
    );
    if (!_playedIntro) {
      _playedIntro = true;
      await _playAsset(copy.primary.instructionAssetId);
    }
  }

  Future<void> _complete() async {
    final lesson = _lesson;
    final profile = ref.read(sessionProvider).value;
    final copy = _copy;
    if (lesson is! SupportedLesson || profile == null || copy == null) return;
    final started = _startedAt ?? DateTime.now().toUtc();
    await ref
        .read(repositoryProvider)
        .applyEvent(
          profileId: profile.profileId,
          categoryId: lesson.document.categoryId,
          event: LearningEvent(
            eventId: uuidV4(),
            contentId: lesson.document.contentId,
            contentVersion: lesson.document.contentVersion,
            eventType: 'completed',
            occurredAt: DateTime.now().toUtc(),
            durationBucket: durationBucketFor(
              DateTime.now().toUtc().difference(started),
            ),
          ),
        );
    if (mounted) setState(() => _feedback = copy.primary.feedbackCorrect);
  }

  Future<void> _playAsset(String? assetId) async {
    if (assetId == null) {
      if (mounted) setState(() => _audioMissing = true);
      return;
    }
    final blob = await ref.read(repositoryProvider).getBlob(assetId);
    if (blob == null || sha256Hex(blob.bytes) != blob.sha256) {
      if (mounted) setState(() => _audioMissing = true);
      return;
    }
    try {
      await ref
          .read(playbackProvider.notifier)
          .play(blob.bytes, playbackMediaType(blob.mediaType));
    } catch (_) {
      if (mounted) setState(() => _audioMissing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final download = ref.watch(downloadProvider);
    ref.listen(downloadProvider, (previous, next) {
      if (next.phase == DownloadPhase.saved &&
          next.contentId == widget.contentId) {
        _load();
      }
    });
    if (_kind == _PlayerKind.loading) {
      return PageFrame(
        onHome: () => context.go('/'),
        child: Center(child: Text(text.downloading)),
      );
    }
    if (_kind == _PlayerKind.checksum) {
      return PageFrame(
        onHome: () => context.go('/'),
        child: Center(
          child: Text(text.checksumError, textAlign: TextAlign.center),
        ),
      );
    }
    if (_kind == _PlayerKind.missing) {
      final busy = download.phase == DownloadPhase.downloading;
      return PageFrame(
        onHome: () => context.go('/'),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(text.downloadFirst),
            if (download.phase == DownloadPhase.failed)
              Text(text.downloadFailed),
            if (download.phase == DownloadPhase.checksum)
              Text(text.checksumError),
            const SizedBox(height: 16),
            BigButton(
              label: busy ? text.downloading : text.downloadAction,
              icon: Icons.download,
              onPressed: busy
                  ? null
                  : () => ref
                        .read(downloadProvider.notifier)
                        .start(widget.contentId),
            ),
            if (busy)
              BigButton(
                label: text.cancel,
                icon: Icons.close,
                onPressed: () => ref.read(downloadProvider.notifier).cancel(),
              ),
          ],
        ),
      );
    }
    final lesson = _lesson!;
    final copy = _copy;
    return PageFrame(
      child: LessonRenderer(
        lesson: lesson,
        instruction: copy?.primary.instruction ?? '',
        secondaryTitle: copy?.secondary?.title,
        feedback: _feedback,
        imageBytes: _image,
        imageLabel: _imageLabel,
        audioMissing: _audioMissing,
        onTarget: _complete,
        onHome: () => context.go('/'),
        onBack: () => context.go(
          '/c/${lesson is SupportedLesson ? lesson.document.categoryId : 'animals'}',
        ),
        onPlay: () => _playAsset(copy?.primary.instructionAssetId),
        onPause: () => ref.read(playbackProvider.notifier).pause(),
        onReplay: () => _playAsset(copy?.primary.instructionAssetId),
        onReplayOther: copy?.secondary?.instructionAssetId == null
            ? null
            : () => _playAsset(copy?.secondary?.instructionAssetId),
      ),
    );
  }
}

enum _PlayerKind { loading, missing, checksum, ready }

LocalizedCopy _copyOf(LessonLocalization value) {
  return LocalizedCopy(
    title: value.title,
    instruction: value.instruction,
    feedbackCorrect: value.feedbackCorrect,
    instructionAssetId: value.audio?.instructionAssetId,
  );
}
