class Playback {
  const Playback({this.playing = false, this.waitingForTap = false});

  final bool playing;
  final bool waitingForTap;

  /// Coming back to the app never starts audio by itself.
  bool get resumeOnForeground => false;

  Playback userPlay() => const Playback(playing: true);

  Playback userPause() => const Playback();

  Playback background() => Playback(waitingForTap: playing);
}
