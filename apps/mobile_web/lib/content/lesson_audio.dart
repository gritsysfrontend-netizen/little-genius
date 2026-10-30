import 'dart:typed_data';

abstract class LessonAudio {
  Future<void> play(Uint8List bytes, String mediaType);
  Future<void> pause();
  Future<void> dispose();
}

class NoopLessonAudio implements LessonAudio {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play(Uint8List bytes, String mediaType) async {}
}
