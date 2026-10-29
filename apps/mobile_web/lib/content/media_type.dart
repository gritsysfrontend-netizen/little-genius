String playbackMediaType(String mediaType) {
  if (mediaType.contains('/')) return mediaType;
  return switch (mediaType) {
    'audio' || 'sound_effect' => 'audio/mpeg',
    'image' => 'image/png',
    _ => 'application/octet-stream',
  };
}
