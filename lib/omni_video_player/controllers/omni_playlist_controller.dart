import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_item.dart';

/// A controller that manages playlist state, navigation, and auto-advance behavior.
///
/// [OmniPlaylistController] coordinates with the underlying [OmniPlaybackController]
/// to switch between videos in a playlist. It handles:
///
/// - Sequential, shuffle, and repeat playback modes
/// - Auto-advance with countdown timer
/// - Next/Previous/JumpTo navigation
/// - Dynamic queue management (add, remove, reorder)
///
/// ### Usage
/// ```dart
/// final playlistController = OmniPlaylistController(
///   configuration: PlaylistConfiguration(
///     items: [...],
///     autoAdvance: true,
///     repeatMode: PlaylistRepeatMode.all,
///   ),
/// );
///
/// // Navigate
/// playlistController.next();
/// playlistController.previous();
/// playlistController.jumpTo(3);
///
/// // Listen for changes
/// playlistController.addListener(() {
///   print('Now playing index: ${playlistController.currentIndex}');
/// });
/// ```
class OmniPlaylistController extends ChangeNotifier {
  /// Creates a new playlist controller with the given configuration.
  OmniPlaylistController({
    required PlaylistConfiguration configuration,
    PlaylistCallbacks? callbacks,
  })  : _items = List<OmniPlaylistItem>.from(configuration.items),
        _currentIndex = configuration.initialIndex.clamp(
          0,
          configuration.items.length - 1,
        ),
        _autoAdvance = configuration.autoAdvance,
        _repeatMode = configuration.repeatMode,
        _isShuffled = configuration.shuffled,
        _advanceDelay = configuration.advanceDelay,
        _callbacks = callbacks {
    if (_isShuffled) {
      _generateShuffleOrder();
    }
  }

  // ──────────────── Internal State ────────────────

  final List<OmniPlaylistItem> _items;
  int _currentIndex;
  bool _autoAdvance;
  PlaylistRepeatMode _repeatMode;
  bool _isShuffled;
  final Duration _advanceDelay;
  PlaylistCallbacks? _callbacks;

  /// The shuffle order (indices into [_items]).
  List<int>? _shuffleOrder;

  /// The current position within the shuffle order.
  int _shufflePosition = 0;

  /// Whether auto-advance is currently counting down.
  bool _isAutoAdvancing = false;

  /// Remaining seconds in the auto-advance countdown.
  int _autoAdvanceCountdown = 0;

  /// Timer for auto-advance countdown.
  Timer? _autoAdvanceTimer;

  /// Reference to the current playback controller (set by the widget).
  OmniPlaybackController? _playbackController;

  /// Whether this controller has been disposed.
  bool _disposed = false;

  /// A callback that the playlist widget registers to handle source changes.
  /// This is called when the playlist needs to load a new video source.
  void Function(int index)? onSourceChangeRequested;

  // ──────────────── Public Getters ────────────────

  /// The list of all playlist items.
  List<OmniPlaylistItem> get items => List.unmodifiable(_items);

  /// The index of the currently playing video.
  int get currentIndex => _currentIndex;

  /// The currently playing playlist item.
  OmniPlaylistItem get currentItem => _items[_currentIndex];

  /// The total number of items in the playlist.
  int get itemCount => _items.length;

  /// Whether there is a next video to play.
  bool get hasNext {
    if (_repeatMode == PlaylistRepeatMode.all) return _items.length > 1;
    if (_isShuffled && _shuffleOrder != null) {
      return _shufflePosition < _shuffleOrder!.length - 1;
    }
    return _currentIndex < _items.length - 1;
  }

  /// Whether there is a previous video to go back to.
  bool get hasPrevious {
    if (_repeatMode == PlaylistRepeatMode.all) return _items.length > 1;
    if (_isShuffled && _shuffleOrder != null) {
      return _shufflePosition > 0;
    }
    return _currentIndex > 0;
  }

  /// Whether the playlist is currently auto-advancing (countdown active).
  bool get isAutoAdvancing => _isAutoAdvancing;

  /// The remaining seconds in the auto-advance countdown.
  int get autoAdvanceCountdown => _autoAdvanceCountdown;

  /// Whether auto-advance is enabled.
  bool get autoAdvance => _autoAdvance;

  /// The current repeat mode.
  PlaylistRepeatMode get repeatMode => _repeatMode;

  /// Whether shuffle mode is active.
  bool get isShuffled => _isShuffled;

  /// The delay before auto-advancing.
  Duration get advanceDelay => _advanceDelay;

  /// The current playback controller (if available).
  OmniPlaybackController? get playbackController => _playbackController;

  /// Whether this controller has been disposed.
  bool get isDisposed => _disposed;

  /// The next item that will be played (for "Up Next" display), or null if none.
  OmniPlaylistItem? get nextItem {
    final nextIdx = _getNextIndex();
    if (nextIdx == null) return null;
    return _items[nextIdx];
  }

  // ──────────────── Playback Controller Binding ────────────────

  /// Binds the playback controller from the video player widget.
  ///
  /// This is called internally by [OmniVideoPlaylist] when a new controller
  /// is created.
  void bindPlaybackController(OmniPlaybackController controller) {
    _playbackController = controller;
    notifyListeners();
  }

  /// Unbinds the current playback controller.
  void unbindPlaybackController() {
    _playbackController = null;
  }

  // ──────────────── Navigation ────────────────

  /// Advances to the next video in the playlist.
  ///
  /// Respects shuffle order and repeat mode.
  /// Returns `true` if navigation succeeded, `false` if at the end.
  bool next() {
    if (_disposed) return false;
    cancelAutoAdvance();

    final nextIdx = _getNextIndex();
    if (nextIdx == null) {
      _callbacks?.onPlaylistFinished?.call();
      return false;
    }

    _callbacks?.onAdvancing?.call(_currentIndex, nextIdx);
    _navigateTo(nextIdx);
    return true;
  }

  /// Goes back to the previous video in the playlist.
  ///
  /// If the current video has played for more than 3 seconds, it restarts
  /// the current video instead of going to the previous one.
  ///
  /// Returns `true` if navigation occurred, `false` if at the beginning.
  bool previous() {
    if (_disposed) return false;
    cancelAutoAdvance();

    // If current video has been playing for > 3 seconds, restart it
    if (_playbackController != null &&
        _playbackController!.currentPosition > const Duration(seconds: 3)) {
      _playbackController!.seekTo(Duration.zero);
      return true;
    }

    final prevIdx = _getPreviousIndex();
    if (prevIdx == null) return false;

    _navigateTo(prevIdx);
    return true;
  }

  /// Jumps to a specific index in the playlist.
  ///
  /// [index] must be within `[0, itemCount)`.
  void jumpTo(int index) {
    if (_disposed) return;
    if (index < 0 || index >= _items.length) {
      throw RangeError.range(index, 0, _items.length - 1, 'index');
    }
    cancelAutoAdvance();

    if (index == _currentIndex) {
      // Restart current video
      _playbackController?.seekTo(Duration.zero);
      _playbackController?.play();
      return;
    }

    _navigateTo(index);
  }

  /// Called when the current video finishes playing.
  ///
  /// Fires [onVideoItemCompleted] first, then handles repeat/auto-advance.
  void onVideoFinished() {
    if (_disposed) return;

    // Notify per-item completion before any navigation/repeat logic
    _callbacks?.onVideoItemCompleted?.call(
      _currentIndex,
      _items[_currentIndex],
    );

    if (_repeatMode == PlaylistRepeatMode.one) {
      _playbackController?.replay();
      return;
    }

    if (_autoAdvance && hasNext) {
      _startAutoAdvance();
    } else if (!hasNext) {
      _callbacks?.onPlaylistFinished?.call();
    }
  }

  // ──────────────── Auto-Advance ────────────────

  /// Starts the auto-advance countdown timer.
  void _startAutoAdvance() {
    if (_disposed) return;

    final nextIdx = _getNextIndex();
    if (nextIdx == null) return;

    _isAutoAdvancing = true;
    _autoAdvanceCountdown = _advanceDelay.inSeconds;
    notifyListeners();

    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      _autoAdvanceCountdown--;
      notifyListeners();

      if (_autoAdvanceCountdown <= 0) {
        timer.cancel();
        _isAutoAdvancing = false;
        notifyListeners();
        next();
      }
    });
  }

  /// Cancels the auto-advance countdown if one is active.
  void cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
    if (_isAutoAdvancing) {
      _isAutoAdvancing = false;
      notifyListeners();
    }
  }

  /// Skips the countdown and immediately advances to the next video.
  void skipAutoAdvanceCountdown() {
    cancelAutoAdvance();
    next();
  }

  // ──────────────── Mode Controls ────────────────

  /// Sets the auto-advance behavior.
  set autoAdvance(bool value) {
    if (_autoAdvance != value) {
      _autoAdvance = value;
      notifyListeners();
    }
  }

  /// Cycles through repeat modes: none → all → one → none.
  void cycleRepeatMode() {
    switch (_repeatMode) {
      case PlaylistRepeatMode.none:
        _repeatMode = PlaylistRepeatMode.all;
        break;
      case PlaylistRepeatMode.all:
        _repeatMode = PlaylistRepeatMode.one;
        break;
      case PlaylistRepeatMode.one:
        _repeatMode = PlaylistRepeatMode.none;
        break;
    }
    _callbacks?.onRepeatModeChanged?.call(_repeatMode);
    notifyListeners();
  }

  /// Sets the repeat mode directly.
  set repeatMode(PlaylistRepeatMode mode) {
    if (_repeatMode != mode) {
      _repeatMode = mode;
      _callbacks?.onRepeatModeChanged?.call(_repeatMode);
      notifyListeners();
    }
  }

  /// Toggles shuffle mode on/off.
  void toggleShuffle() {
    _isShuffled = !_isShuffled;
    if (_isShuffled) {
      _generateShuffleOrder();
    } else {
      _shuffleOrder = null;
    }
    _callbacks?.onShuffleToggled?.call(_isShuffled);
    notifyListeners();
  }

  // ──────────────── Queue Management ────────────────

  /// Adds an item to the end of the playlist.
  void addItem(OmniPlaylistItem item) {
    _items.add(item);
    if (_isShuffled) {
      _shuffleOrder?.add(_items.length - 1);
    }
    notifyListeners();
  }

  /// Inserts an item at the specified index.
  void insertItem(int index, OmniPlaylistItem item) {
    _items.insert(index, item);
    // Adjust current index if item was inserted before it
    if (index <= _currentIndex) {
      _currentIndex++;
    }
    if (_isShuffled) {
      _generateShuffleOrder();
    }
    notifyListeners();
  }

  /// Removes the item at the specified index.
  ///
  /// Cannot remove the currently playing item.
  /// Returns the removed item, or null if removal was not possible.
  OmniPlaylistItem? removeItemAt(int index) {
    if (index < 0 || index >= _items.length || _items.length <= 1) return null;
    if (index == _currentIndex) return null; // Can't remove current

    final removed = _items.removeAt(index);

    // Adjust current index if needed
    if (index < _currentIndex) {
      _currentIndex--;
    }

    if (_isShuffled) {
      _generateShuffleOrder();
    }

    notifyListeners();
    return removed;
  }

  /// Reorders an item from [oldIndex] to [newIndex].
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _items.length ||
        newIndex < 0 ||
        newIndex >= _items.length) {
      return;
    }

    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);

    // Adjust current index
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex--;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex++;
    }

    if (_isShuffled) {
      _generateShuffleOrder();
    }

    notifyListeners();
  }

  /// Updates the callbacks.
  set callbacks(PlaylistCallbacks? value) {
    _callbacks = value;
  }

  // ──────────────── Private Helpers ────────────────

  void _navigateTo(int newIndex) {
    _currentIndex = newIndex;

    // Update shuffle position if in shuffle mode
    if (_isShuffled && _shuffleOrder != null) {
      _shufflePosition = _shuffleOrder!.indexOf(newIndex);
    }

    _callbacks?.onVideoChanged?.call(newIndex, _items[newIndex]);
    onSourceChangeRequested?.call(newIndex);
    notifyListeners();
  }

  int? _getNextIndex() {
    if (_isShuffled && _shuffleOrder != null) {
      if (_shufflePosition < _shuffleOrder!.length - 1) {
        return _shuffleOrder![_shufflePosition + 1];
      } else if (_repeatMode == PlaylistRepeatMode.all) {
        _generateShuffleOrder(); // Re-shuffle for next cycle
        return _shuffleOrder![0];
      }
      return null;
    }

    if (_currentIndex < _items.length - 1) {
      return _currentIndex + 1;
    } else if (_repeatMode == PlaylistRepeatMode.all) {
      return 0;
    }
    return null;
  }

  int? _getPreviousIndex() {
    if (_isShuffled && _shuffleOrder != null) {
      if (_shufflePosition > 0) {
        return _shuffleOrder![_shufflePosition - 1];
      } else if (_repeatMode == PlaylistRepeatMode.all) {
        return _shuffleOrder!.last;
      }
      return null;
    }

    if (_currentIndex > 0) {
      return _currentIndex - 1;
    } else if (_repeatMode == PlaylistRepeatMode.all) {
      return _items.length - 1;
    }
    return null;
  }

  void _generateShuffleOrder() {
    final indices = List<int>.generate(_items.length, (i) => i);
    indices.shuffle(Random());

    // Ensure current item is at the front of the shuffle
    indices.remove(_currentIndex);
    indices.insert(0, _currentIndex);

    _shuffleOrder = indices;
    _shufflePosition = 0;
  }

  @override
  void dispose() {
    _disposed = true;
    cancelAutoAdvance();
    _playbackController = null;
    super.dispose();
  }
}
