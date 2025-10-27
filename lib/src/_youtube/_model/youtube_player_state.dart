enum YoutubePlayerState {
  /// Denotes State when player is not loaded with video.
  unknown(-2),

  /// Denotes state when player loads first video.
  unStarted(-1),

  /// Denotes state when player has ended playing a video.
  ended(0),

  /// Denotes state when player is playing video.
  playing(1),

  /// Denotes state when player is paused.
  paused(2),

  /// Denotes state when player is buffering bytes from the internet.
  buffering(3),

  /// Denotes state when player loads video and is ready to be played.
  cued(5);

  const YoutubePlayerState(this.code);
  final int code;
}
