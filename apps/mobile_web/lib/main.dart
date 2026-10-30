import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'content/just_audio_player.dart';
import 'data/open_repository.dart';
import 'routing/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await openLearningRepository();
  runApp(
    ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(repository),
        lessonAudioProvider.overrideWith((ref) {
          final audio = JustLessonAudio();
          ref.onDispose(audio.dispose);
          return audio;
        }),
      ],
      child: const LittleGeniusApp(),
    ),
  );
}
