import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/lesson_audio.dart';
import '../data/downloader.dart';
import '../data/learning_repository.dart';
import '../domain/gate_policy.dart';
import '../domain/playback.dart';
import '../domain/profile.dart';

final repositoryProvider = Provider<LearningRepository>((ref) {
  throw StateError('LearningRepository is provided at startup.');
});

final lessonAudioProvider = Provider<LessonAudio>((ref) => NoopLessonAudio());

final byteSourceProvider = Provider<ByteSource>((ref) {
  final dio = Dio();
  ref.onDispose(dio.close);
  return DioByteSource(dio);
});

final draftLocaleProvider = NotifierProvider<DraftLocale, String>(
  DraftLocale.new,
);

class DraftLocale extends Notifier<String> {
  @override
  String build() => 'en';

  void setLocale(String locale) => state = locale;
}

final sessionProvider = AsyncNotifierProvider<SessionController, ChildProfile?>(
  SessionController.new,
);

class SessionController extends AsyncNotifier<ChildProfile?> {
  @override
  Future<ChildProfile?> build() async {
    final repository = ref.watch(repositoryProvider);
    final id = await repository.getActiveProfileId();
    if (id == null) return null;
    return repository.getProfile(id);
  }

  Future<void> adopt(ChildProfile profile) async {
    await ref.read(repositoryProvider).setActiveProfileId(profile.profileId);
    state = AsyncData(profile);
  }

  Future<void> save(ChildProfile profile) async {
    final saved = await ref.read(repositoryProvider).updateProfile(profile);
    state = AsyncData(saved);
  }
}

final parentGateProvider = NotifierProvider<ParentGate, bool>(ParentGate.new);

class ParentGate extends Notifier<bool> {
  DateTime? hiddenAt;
  DateTime Function() clock = DateTime.now;

  @override
  bool build() => false;

  void unlock() => state = true;

  void lock() {
    hiddenAt = null;
    state = false;
  }

  void onLifecycle(AppLifecycleState lifecycle) {
    final next = advanceGate(
      unlocked: state,
      hiddenAt: hiddenAt,
      lifecycle: lifecycle,
      now: clock(),
    );
    hiddenAt = next.hiddenAt;
    if (next.unlocked != state) state = next.unlocked;
  }
}

final playbackProvider = NotifierProvider<AudioCoordinator, Playback>(
  AudioCoordinator.new,
);

class AudioCoordinator extends Notifier<Playback> {
  @override
  Playback build() => const Playback();

  Future<void> play(Uint8List bytes, String mediaType) async {
    state = state.userPlay();
    try {
      await ref.read(lessonAudioProvider).play(bytes, mediaType);
    } catch (error) {
      state = state.userPause();
      rethrow;
    }
  }

  Future<void> pause() async {
    state = state.userPause();
    await ref.read(lessonAudioProvider).pause();
  }

  Future<void> background() async {
    final wasPlaying = state.playing;
    state = state.background();
    if (wasPlaying) await ref.read(lessonAudioProvider).pause();
  }

  void foreground() {
    // Playback.resumeOnForeground is false. A tap is required.
  }
}

enum DownloadPhase { idle, downloading, failed, checksum, saved }

class DownloadState {
  const DownloadState({this.phase = DownloadPhase.idle, this.contentId});

  final DownloadPhase phase;
  final String? contentId;
}

final downloadProvider = NotifierProvider<DownloadController, DownloadState>(
  DownloadController.new,
);

class DownloadController extends Notifier<DownloadState> {
  DownloadCancelToken? _token;

  @override
  DownloadState build() => const DownloadState();

  Future<void> start(String contentId) async {
    _token?.cancel();
    final token = DownloadCancelToken();
    _token = token;
    state = DownloadState(
      phase: DownloadPhase.downloading,
      contentId: contentId,
    );
    final outcome = await LessonDownloader(
      source: ref.read(byteSourceProvider),
      repository: ref.read(repositoryProvider),
    ).download(contentId: contentId, token: token);
    if (!identical(_token, token)) return;
    state = DownloadState(phase: _phase(outcome.status), contentId: contentId);
  }

  void cancel() {
    _token?.cancel();
    _token = null;
    state = const DownloadState();
  }

  DownloadPhase _phase(DownloadStatus status) {
    return switch (status) {
      DownloadStatus.saved => DownloadPhase.saved,
      DownloadStatus.cancelled => DownloadPhase.idle,
      DownloadStatus.checksumMismatch => DownloadPhase.checksum,
      DownloadStatus.failed => DownloadPhase.failed,
    };
  }
}

class RouterRefresh extends ChangeNotifier {
  void ping() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefresh>((ref) {
  final refresh = RouterRefresh();
  ref.onDispose(refresh.dispose);
  ref.listen(sessionProvider, (_, _) => refresh.ping());
  ref.listen(parentGateProvider, (_, _) => refresh.ping());
  return refresh;
});
