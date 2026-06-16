import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_configuration.dart';

/// Manages the queue and navigation state of a minimal [OmniVideoPlaylist].
///
/// Holds an ordered list of [VideoSourceConfiguration]s and the current index,
/// exposing [next]/[previous]/[jumpTo]. With [PlaylistConfiguration.loop] the
/// ends wrap around. The widget listens to this controller to re-mount the
/// player on the current source and to enable/disable the nav buttons.
class OmniPlaylistController extends ChangeNotifier {
  OmniPlaylistController({
    required PlaylistConfiguration configuration,
    PlaylistCallbacks? callbacks,
  })  : _items = List<VideoSourceConfiguration>.from(configuration.items),
        _currentIndex = configuration.items.isEmpty
            ? 0
            : configuration.initialIndex
                .clamp(0, configuration.items.length - 1),
        _loop = configuration.loop,
        _autoAdvance = configuration.autoAdvance,
        _callbacks = callbacks {
    if (configuration.items.isEmpty) {
      throw ArgumentError.value(
        configuration.items,
        'configuration.items',
        'Playlist must contain at least one item.',
      );
    }
  }

  final List<VideoSourceConfiguration> _items;
  int _currentIndex;
  final bool _loop;
  final bool _autoAdvance;
  final PlaylistCallbacks? _callbacks;
  bool _disposed = false;

  /// Set by the widget to re-mount the player when the current index changes.
  void Function(int index)? onSourceChangeRequested;

  int get currentIndex => _currentIndex;
  VideoSourceConfiguration get currentSource => _items[_currentIndex];
  int get itemCount => _items.length;
  bool get loop => _loop;
  bool get autoAdvance => _autoAdvance;
  bool get isDisposed => _disposed;

  bool get hasNext =>
      _loop ? _items.length > 1 : _currentIndex < _items.length - 1;
  bool get hasPrevious =>
      _loop ? _items.length > 1 : _currentIndex > 0;

  /// Advances to the next video (wraps if looping). Returns false if none.
  bool next() {
    if (_disposed || !hasNext) return false;
    _navigateTo(_currentIndex >= _items.length - 1 ? 0 : _currentIndex + 1);
    return true;
  }

  /// Goes to the previous video (wraps if looping). Returns false if none.
  bool previous() {
    if (_disposed || !hasPrevious) return false;
    _navigateTo(_currentIndex <= 0 ? _items.length - 1 : _currentIndex - 1);
    return true;
  }

  /// Jumps to [index] (`[0, itemCount)`); throws [RangeError] if out of range.
  void jumpTo(int index) {
    if (_disposed) return;
    if (index < 0 || index >= _items.length) {
      throw RangeError.range(index, 0, _items.length - 1, 'index');
    }
    if (index == _currentIndex) return;
    _navigateTo(index);
  }

  /// Called by the widget when the current video finishes.
  ///
  /// Only acts when [autoAdvance] is enabled: advances to the next video, or
  /// fires [PlaylistCallbacks.onPlaylistCompleted] when there is no next and
  /// looping is off. In manual mode it does nothing (the player shows replay).
  void handleVideoFinished() {
    if (_disposed || !_autoAdvance) return;
    if (hasNext) {
      next();
    } else {
      _callbacks?.onPlaylistCompleted?.call();
    }
  }

  void _navigateTo(int index) {
    if (_disposed) return;
    _currentIndex = index;
    _callbacks?.onVideoChanged?.call(index);
    onSourceChangeRequested?.call(index);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
