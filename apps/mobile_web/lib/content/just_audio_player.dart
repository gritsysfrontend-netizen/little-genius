import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

import 'audio_bytes_stub.dart'
    if (dart.library.io) 'audio_bytes_io.dart'
    if (dart.library.js_interop) 'audio_bytes_web.dart';
import 'lesson_audio.dart';

class JustLessonAudio implements LessonAudio {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(Uint8List bytes, String mediaType) async {
    await _player.stop();
    final uri = await uriForBytes(bytes, mediaType);
    await _player.setAudioSource(AudioSource.uri(uri));
    await _player.setLoopMode(LoopMode.off);
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}
