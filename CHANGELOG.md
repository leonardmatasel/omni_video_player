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
