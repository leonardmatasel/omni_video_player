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
