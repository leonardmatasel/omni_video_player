# 3.3.3

⬆️ **Updates dependencies · Improvement**

* Updated all dependencies.
* Improved YouTube WebView player and removed all YouTube branding.

# 3.3.2

🛠 **Fix**

* Fixed **orientation and fullscreen exit issues** on Android and iOS.

  * App no longer remains stuck in **landscape mode** after closing fullscreen.
  * See issue: [#9](https://github.com/leonardmatasel/omni_video_player/issues/9)

# 3.3.1

🛠 **Fix**

* Fixed **autoplay not working** issue on Web.
  - See issue: [#46](https://github.com/leonardmatasel/omni_video_player/issues/46)
* Removed **white border** appearing on top and left sides in Web player.
  - See issue: [#47](https://github.com/leonardmatasel/omni_video_player/issues/47)

# 3.3.0

🛠 **Bug Fixes · Renaming · Code Refactor** 

* Fixed several minor bugs improving playback stability and UI consistency.
* Thanks to [**@Md-Sifatullah617**](https://github.com/Md-Sifatullah617) for contributing a fix to one of the issues. 🙌
* The parameter `options` in `OmniVideoPlayer` has been renamed to `configuration` for clarity.

# 3.2.2

⬆️ **Updates dependencies**

# 3.2.1 - 3.2.0

🛠 **Refactor / Improvement**

* Reduced reliance on external libraries (from 5 libraries for web view management) and refactored to use the new `flutter_inappwebview` dependency.

# 3.1.11 - 3.1.10

✨ **New Features**

* Enhanced **accessibility** throughout the `OmniVideoPlayer`.

  * The video player has been **made fully accessible**, ensuring it can be properly used by **visually impaired users**.
  * Introduced a new `VideoPlayerAccessibilityTheme` parameter in `OmniVideoPlayerThemeData`, allowing developers to **customize semantic labels and accessibility messages** for all player controls and overlays.

# 3.1.9

🛠 **Fix**

* Fixed YouTube WebView playback issue
  - See issue: [#37](https://github.com/leonardmatasel/omni_video_player/issues/37)

# 3.1.8

🛠 **Fix**

* Improved **video startup performance** for long videos on iOS.
  - See issue: [#37](https://github.com/leonardmatasel/omni_video_player/issues/37)
  - See issue: [#40](https://github.com/leonardmatasel/omni_video_player/issues/40)

# 3.1.7

🛠 **Fix**

* Fixed issue with **exiting fullscreen** in release mode.
  - See issue: [#38](https://github.com/leonardmatasel/omni_video_player/issues/38)

# 3.1.6

🛠 **Fix**

* Fixed several **minor issues in the player** related to video controller management and playback of certain network sources.
* Removed the `refreshOnUrlReuse` parameter, which is **no longer valid** and no longer used by the player.

# 3.1.5

✨ **New Features**

* Added `refreshOnUrlReuse` parameter to `VideoSourceConfiguration.network`.

  * When set to `true`, the player will **always create a new controller** even if a controller for the same `videoUrl` already exists in cache.
  * This is particularly useful when working with **temporary or expiring network URLs** (e.g., signed or tokenized URLs) that may return HTTP 400/403 errors if reused.
  * **Default:** `false`


# 3.1.4 - 3.1.0

🛠 **Fix**

* Fixed minor playback issues 
* Removed a package dependency to reduce overall bundle size.
* Added automatic retry logic when entering an error state — the player now retries initialization up to **3 times** before failing definitively.

# 3.0.21

✨ **New Features**

* Added `showBottomControlsBarOnPause` parameter to `PlayerUIVisibilityOptions`.

  * When set to `true`, the bottom control bar remains **visible while the video is paused**, providing easier access to playback controls during pause state.
  * **Default:** `false`

# 3.0.20

✨ **New Features**

* Added `alwaysShowBottomControlsBar` parameter to `PlayerUIVisibilityOptions`.

  * When set to `true`, the bottom control bar is **always visible**, even when the video is paused or hasn't started yet.
  * **Default:** `false`

# 3.0.19 - 3.0.13

🛠 **Refactor / Improvement**

* Added a singleton `VideoPlaybackControllerPool` to reuse `VideoPlaybackController` instances.

  * Reuses the existing controller if the requested URI is the same and already initialized.
  * Disposes and recreates the controller only when switching to a new URI or after an initialization failure.
  * Simplifies controller management and reduces unnecessary decoder creation, improving performance and memory usage.

# 3.0.12 - 3.0.11

🛠 **Fix**

* Added automatic retry for `VideoPlaybackController` initialization.

  * Retries up to **3 times** with **250 ms delay** between attempts to prevent intermittent
    `OMX.qcom.video.decoder.avc (NO_MEMORY)` crashes on some Android devices when switching videos rapidly.

# 3.0.10 - 3.0.8

✨ **New Features**

* Added `keepAlive` parameter to `VideoSourceConfiguration`.

  * When set to `true`, the video controller is **not automatically disposed**, allowing the video state to persist between rebuilds or navigation changes.
  * **Default:** `false`
  * ⚠️ Use with caution — if you never call `dispose()` manually, this may cause memory leaks or OutOfMemory errors.


🛠 **Fix**

* Fixed occasional `OMX.qcom.video.decoder.avc (NO_MEMORY)` crash on Android.

  * Set `mixWithOthers` to `false` in `VideoPlaybackController` to prevent hardware decoder conflicts when multiple players or audio sessions are active.

#  3.0.7 - 3.0.5

🛠 **Fix / UI**

* Fixed `ProgressBar` crash in fullscreen.

  * Prevents invalid `clamp` arguments when video starts or panel layouts reduce available width.

# 3.0.4

🧹 **Removals**

* Removed unused parameters in `VideoPlayerLabelTheme`:
  * `openExternalLabel`
  * `refreshLabel`
* These labels were not used anywhere in the player and have been removed to simplify the API.

# 3.0.3

✨ **New Features**

* **Fullscreen wrapper support** via `CustomPlayerWidgets.fullscreenWrapper`.

  * Allows wrapping the entire fullscreen player with a custom widget or layout.

# 3.0.1 - 3.0.2

🛠 **Fix**

* Dart formatter

# 3.0.0

💥 **Breaking Changes**

* Removed **global playback control system** (`GlobalPlaybackControlSettings` and `GlobalPlaybackController` usage).
  App initialization is now simplified — no `BlocProvider` needed.

* Removed parameters from `PlayerUIVisibilityOptions`:
  `showRefreshButtonInErrorPlaceholder`, `showOpenExternallyInErrorPlaceholder`.

* **`VideoPlayerErrorPlaceholder`** simplified — now displays only the themed error icon and message.
  If you want to keep using the previous version, you can pass it through `CustomPlayerWidgets.errorPlaceholder`.
  The old implementation is available here: [Old Video Player Error Placeholder](https://github.com/leonardmatasel/omni_video_player/blob/main/example/lib/custom_widgets/video_player_error_placeholder.dart).

* `synchronizeMuteAcrossPlayers` moved to `VideoSourceConfiguration`.

➡️ For migration details, see [MIGRATION_GUIDE.md](https://github.com/leonardmatasel/omni_video_player/blob/main/MIGRATION_GUIDE.md)

🧩 **Package Simplification**

* Removed dependencies: `flutter_bloc`, `android_intent_plus`, `url_launcher`, `built_collection`.


# 2.3.22

✨ **New Features**

* **Device volume support** via **`volume_controller`**.

  * GlobalPlaybackController now listens to hardware volume changes.
  * Automatically updates mute/unmute state based on system volume.
  * No separate listener widget needed — single `BlocProvider<GlobalPlaybackController>` is enough.

# 2.3.21

🛠 **Fix**

* Update exports

# 2.3.20

🛠 **Fix**

* Fix issue with error into initializer

# 2.3.19

✨ **New Features**

* Add **`showOpenExternallyInErrorPlaceholder`** option to `PlayerUIVisibilityOptions`

  * When set to `true`, displays a **“Open Externally” button** inside the **error placeholder** if video playback fails.
  * Defaults to `true`.
  * Enables users to open the video in an external app or browser when the player encounters an error.

# 2.3.18

✨ **New Features**

* Add **`onSeekRequest`** callback to `VideoPlayerCallbacks`

  * Invoked **before** a seek operation is performed.
  * Returns a `bool` indicating whether the seek should proceed (`true`) or be cancelled (`false`).
  * Useful for implementing custom seek restrictions or validations.
  * ⚠️ *Available only for videos that are **not rendered inside a WebView***
  
# 2.3.17

🛠 **Fix**

* Fix issue with swipe to exit from fullscreen
 
# 2.3.16

🛠 **Fix**

* Fix issue with seeking when the video has ended
  - Previously, attempting to seek after the video finished could cause unexpected behavior.
  - Now, seeking works correctly even when the video is at its end.

# 2.3.14

✨ **New Features**

* Add **`showBottomControlsBarOnEndedFullscreen`** option to `PlayerUIVisibilityOptions`
  - When set to `true`, the **video bottom controls bar** is displayed in **fullscreen** mode after the video ends.
  - Defaults to `false`.
  
# 2.3.13

🛠 **Fix**

* **`showPlayPauseReplayButton`** option to `PlayerUIVisibilityOptions`
  - Applies **only when not in full screen**

# 2.3.12

✨ **New Features**

* Add **`showPlayPauseReplayButton`** option to `PlayerUIVisibilityOptions`
  - Allows controlling the visibility of the main **play / pause / replay overlay button** (centered on the video)
  - Defaults to `true`
  
# 2.3.11

🛠 **Fix**

* Fixed a bug with `youtube_explode_dart` by forcing the use of `YoutubeApiClient.androidVr` when retrieving the video manifest.
  - See issue: [youtube_explode_dart #361](https://github.com/Hexer10/youtube_explode_dart/issues/361)

# 2.3.10

🛠 **Fix**

* Fixed an issue where autoplay videos would start even when the player was no longer visible on screen.
  - See issue: [#29](https://github.com/leonardmatasel/omni_video_player/issues/29)

✨ **New Features**

* Added `timeoutDuration` parameter to `VideoSourceConfiguration`
  - Maximum wait time before considering playback failed
  - Defaults to 6 seconds
  - In the case of YouTube, the player will proceed with the fallback if enabled (default)
  - See issue: [#33](https://github.com/leonardmatasel/omni_video_player/issues/33)

# 2.3.9

✨ **New Features**

* Add support for **dynamically changing the video source** after player initialization.
  - Introduced `loadVideoSource(VideoSourceConfiguration configuration)` in `OmniPlaybackController`
  - Lets you seamlessly switch between YouTube, Vimeo, network, or asset sources without rebuilding the widget — or simply load a different video
  - See issue: [#26](https://github.com/leonardmatasel/omni_video_player/issues/26)

# 2.3.8

🛠 **Fix**

* Fixed Youtube WebView Error

# 2.3.7

✨ **New Features**

* Show **YouTube video thumbnail** while controller initializes.
  - Thumbnail is displayed immediately when available
  - See issue: [#28](https://github.com/leonardmatasel/omni_video_player/issues/28)

# 2.3.6

🛠 **Fix**

* Fixed CHANGELOG
  
# 2.3.5

✨ **New Features**

* Added **video finish callback** support.
  - Introduced `onFinished` in `VideoPlayerCallbacks`.
  - Triggered **once** when a video reaches the end of playback.

* Added **replay callback** support.
  - Introduced `onReplay` in `VideoPlayerCallbacks`.
  - Triggered when the user presses the replay button after video completion.

* See issue: [#25](https://github.com/leonardmatasel/omni_video_player/issues/25)

# 2.3.4

🛠 **Fix**

* Fixed window.onMessage handling by checking if data is String before casting
  - See issue: [#24](https://github.com/leonardmatasel/omni_video_player/issues/24)

# 2.3.3

✨ **New Features**

* Added **keyboard arrow key support** for web.
  - Users can now use the **left (←)** and **right (→)** arrow keys to skip backward and forward during playback.
  - Skip duration follows the same logic as double-tap gestures (5s, 10s, 30s depending on consecutive presses).
  - See issue: [#23](https://github.com/leonardmatasel/omni_video_player/issues/23)

# 2.3.2

✨ **New Features**

* Added `showSwitchWhenOnlyAuto` flag to `PlayerUIVisibilityOptions`.
  - Controls whether the **Switch Quality** button is displayed when no qualities are available and only the "Auto" option would appear in the dialog.
  - Default: `true` (button is still shown with "Auto").
  - If set to `false`, the button will be hidden when only "Auto" is available.
  - See issue: [#22](https://github.com/leonardmatasel/omni_video_player/issues/22)

# 2.3.1

✨ **New Features**

* On YouTube WebView, in addition to showing "auto", the player now also displays the **current playback quality**
  - See issue: [#22](https://github.com/leonardmatasel/omni_video_player/issues/22)
  
# 2.3.0

✨ **New Features**

* Added support for playing videos from the device's **local file system**
  - New factory: `VideoSourceConfiguration.file`
  - See issue: [#18](https://github.com/leonardmatasel/omni_video_player/issues/18)

# 2.2.6

🛠 **Fix**

* Fixed incorrect duration display for YouTube videos in the video player
  - See issue: [#15](https://github.com/leonardmatasel/omni_video_player/issues/15)

# 2.2.5

🛠 **Fix**

* Fixed autoplay issue with Vimeo videos

# 2.2.4

🛠 **Fix**

* Ensure quality menu is always visible, positioned above or below the video depending on available space.
  - See issue: [#22](https://github.com/leonardmatasel/omni_video_player/issues/22)

# 2.2.3

🛠 **Clean code**

# 2.2.2

🛠 **Fix**

* Show HQ quality options for Live YouTube videos that not use `webview`.
  - See issue: [#22](https://github.com/leonardmatasel/omni_video_player/issues/22)
  
# 2.2.1

✨ **New Features**

* Added custom aspect ratio support for both normal and fullscreen modes.

  - New properties in `PlayerUIVisibilityOptions`: `customAspectRatioNormal` and `customAspectRatioFullScreen`.
  - If not provided, the aspect ratio defaults to the one from the video controller.
  
* Added fullscreen orientation support.

  - New property in `PlayerUIVisibilityOptions`: `fullscreenOrientation`.
  - If `null`, the orientation is inferred from the video size (portrait if height > width, otherwise landscape).

# 2.2.0

✨ **New Features**

* Added playback speed support to `VideoSourceConfiguration` and the player UI.

  - New properties: `initialPlaybackSpeed` (default `1.0`) and `availablePlaybackSpeed` (e.g., `[0.5, 1, 1.5, 2]`).
  - Added `showPlaybackSpeedButton` to `PlayerUIVisibilityOptions` to toggle visibility of the speed button.
  - Added `playbackSpeedButton` icon in `VideoPlayerIconTheme` for customization.
  - See issue: [#16](https://github.com/leonardmatasel/omni_video_player/issues/16)
  
* YouTube videos are now playable on web platforms, in addition to mobile.

# 2.1.5

🛠 **Fix**

* Fixed a bug where toggling back from fullscreen caused the status bar to turn black.
  - See issue: [#20](https://github.com/leonardmatasel/omni_video_player/issues/20)

# 2.1.4

🛠 **Fix**

* Fixed some imports
  
# 2.1.3

🛠 **Fix**

* Fixed an aspect ratio issue.
  - See issue: [#17](https://github.com/leonardmatasel/omni_video_player/issues/17)

# 2.1.2

🛠 **Fix**

* Updated supported video codecs to prevent playback errors on Android devices.
  - See issue: [#17](https://github.com/leonardmatasel/omni_video_player/issues/17)

# 2.1.1

🛠 **Fix**

* Fixed an issue on **iOS** where the **Vimeo player failed to initialize**.

# 2.1.0

✨ **Improvements**

* **Vimeo WebView Migration**

  * Replaced `flutter_inappwebview` with `webview_flutter` for Vimeo playback.

# 2.0.11

🛠 **Fix**

* Fixed a problem where some **YouTube videos failed to play** due to no compatible streams being found
  or WebView initialization timing out.
  - See issue: [#13](https://github.com/leonardmatasel/omni_video_player/issues/13)

# 2.0.10

🛠 **Fix**

* Fixed an issue where the `onControllerCreated` callback was invoked **before** the video controller was fully constructed.

  * This caused incorrect initialization behavior for **WebView videos**.

# 2.0.9

✨ **New Features**

* Added `controlsPersistenceDuration` to `PlayerUIVisibilityOptions`.

  - This property controls the duration the video player controls remain visible after user interaction while the video is playing.
  - After this duration without interaction, the controls are hidden automatically.
  - Default value is `Duration(seconds: 3)`.

# 2.0.8

✨ **New Features**

* Added support for disabling automatic orientation lock in fullscreen mode via
  `PlayerUIVisibilityOptions.enableOrientationLock` (default: `true`).

* When set to `false`, the player will **not** change or lock the device orientation in fullscreen,
  allowing manual control over orientation changes (e.g., via your own fullscreen callbacks).


# 2.0.7

🛠 **Fix**

* Fixed audio-video sync issue when seeking in YouTube and network videos.

# 2.0.6

✨ **New Features**

* **YouTube WebView Fallback & Forced Mode**

  * Added two new parameters **inside** `VideoSourceConfiguration.youtube` to improve robustness of YouTube playback:

    * `enableYoutubeWebViewFallback` *(default: `true`)* — enables an **automatic fallback** to a WebView-based YouTube player (via [`webview_flutter`](https://pub.dev/packages/webview_flutter)) when native playback using `youtube_explode_dart` fails.
    * `forceYoutubeWebViewOnly` *(default: `false`)* — skips native extraction entirely and plays YouTube videos **only** through the WebView player.

💡 **Why this change?**
The [`youtube_explode_dart`](https://github.com/Hexer10/youtube_explode_dart) library, used by default to extract YouTube stream URLs, can be temporarily blocked due to **YouTube’s rate-limiting** mechanism when too many requests are made.
When this happens:

* Extraction fails for all videos (even those not previously blocked).
* The issue typically resolves after waiting several hours.
* Using a VPN does not bypass the block.

With this update:

* If **fallback is enabled**, the player transparently switches to the WebView-based implementation, ensuring playback continues without waiting for the rate-limit block to expire.

# 2.0.5

✨ **New Features**

* **HLS (network) video support**:
  - The player now supports **HLS streams** (`.m3u8` files).
  - Allows **quality selection** for network-based HLS videos, just like with YouTube.
  - Controlled via the same `preferredQualities` and `availableQualities` parameters in `VideoSourceConfiguration.network`.
  - Automatically selects the best matching stream based on preferences or falls back to the highest quality.

# 2.0.4

🛠 **Fixes**

* Resolved an issue where **Vimeo videos would not autoplay** as expected.
* Fixed a bug causing the video to **pause unexpectedly** [Issue #8 on GitHub](https://github.com/leonardmatasel/omni_video_player/issues/8)

# 2.0.3

⚠️ **Breaking Change**

The `customOverlayLayer` field in `CustomPlayerWidgets` has been replaced by `customOverlayLayers`, a list of `CustomOverlayLayer` objects.

This allows adding multiple overlays on top of the video content, with fine-grained control over their rendering order.

Overlays are inserted into the rendering stack based on their level and order into list.

# 2.0.2

* Added `ignoreOverlayControlsVisibility` flag to `CustomOverlayLayer`, this allows custom overlays to remain visible even when player controls are hidden (e.g., during auto-hide).

# 2.0.1

✨ **New Features**

- **Custom Overlay Layering Support**:
  - Introduced `CustomOverlayLayer`, allowing insertion of custom widgets into the video player's visual stack.
  - Each overlay can now specify a `level`, which determines its rendering order relative to built-in player elements.

# 2.0.0

⚠️ **Breaking Change**

- `preferredQualities` has changed from `List<int>` to `List<OmniVideoQuality>` to improve clarity and flexibility when selecting video quality.
- Introduced new model: `OmniVideoQuality`, replacing raw integer representations with a structured quality model.

✨ **New Features**

- **YouTube quality switching**:
    - Added support for changing video quality in YouTube playback.
    - Controlled via the new flag: `showSwitchVideoQuality`.
    - New parameter: `availableQualities: List<OmniVideoQuality>?` added to `VideoSourceConfiguration` of YouTube videos.

🎨 **Theming Enhancements**

New theme properties added to `OmniVideoPlayerTheme`:
- `menuBackground` — dropdown background color
- `menuText` — color for unselected quality options
- `menuTextSelected` — color for the selected quality
- `menuIconSelected` — checkmark color for selected quality
- `qualityChangeButton` — icon used to open the quality menu
- `qualitySelectedCheck` — icon used to mark the selected option

# 1.0.6

* Fixed a bug where seeking in long YouTube videos caused noticeable delays

# 1.0.5

* Improvement: autoplay is now managed correctly for better user experience
* No parameter changes needed—just update the package to fix the issue

# 1.0.4

* Feature: Added gesture-based fast-forward (`enableForwardGesture`)
* Feature: Added gesture-based rewind (`enableBackwardGesture`)
* Feature: Added gesture to exit fullscreen on vertical swipe (`enableExitFullscreenOnVerticalSwipe`)
* All new gesture flags are enabled by default


# 1.0.3

* Fix: Fallback to `null` if `GlobalPlaybackController` is not found

# 1.0.2

* Fix bug when `useGlobalPlaybackController`: `false`

# 1.0.1

* Resolve pub.dev analysis issues

# 1.0.0

* Initial development release
