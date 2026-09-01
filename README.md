<h1 align="center">
  <img src="https://github.com/leonardmatasel/omni_video_player/blob/main/example/assets/logo_horizontal.png?raw=true" alt="omni_video_player" height="125"/>
</h1>

<p align="center">
  <strong>The ultimate All-in-One Flutter video solution. Stream YouTube, Vimeo, HLS, and local files with a single, unified controller.</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/omni_video_player">
    <img src="https://img.shields.io/pub/v/omni_video_player.svg" alt="pub version">
  </a>
  <a href="https://pub.dev/packages/omni_video_player/score">
    <img src="https://img.shields.io/pub/points/omni_video_player" alt="pub points">
  </a>
  <a href="https://pub.dev/packages/omni_video_player/score">
    <img src="https://img.shields.io/badge/popularity-high-brightgreen" alt="pub popularity">
  </a>
</p>

## 🚀 Why Omni Video Player?

Stop juggling multiple packages for different video sources. **omni_video_player** wraps the complexity of specialized extractors and webviews into a **single, powerful widget**.

* **Smart YouTube Handling**: Direct extraction via `youtube_explode_dart` with an **automatic WebView fallback**. The player seamlessly switches to WebView if the primary method fails, ensuring uninterrupted playback and no black screens for your users.
* **Vimeo Ready**: Stable playback using optimized WebViews.
* **Adaptive Streaming**: Native support for **HLS (.m3u8)** with built-in **quality selection** UI.
* **Unified Controller**: One controller to rule them all. Manage state, volume, and seeking regardless of the source.

<br>

## 📊 Compatibility Matrix

| Source / Format        | Android | iOS | WebView (Android & iOS - alt/fallback) | Web | Notes                                             |
|------------------------|---------|-----|----------------------------------------|-----|---------------------------------------------------|
| **YouTube**            | ✅       | ✅   | ✅                                      | ✅   | Auto-fallback to WebView on primary method fails. |
| **Vimeo**              | -       | -   | ✅                                      | ✅   | High stability via WebView.                       |
| **HLS (.m3u8)**        | ✅       | ✅   | -                                      | ✅   | **Multi-quality switching** supported.            |
| **Network (.mp4/etc)** | ✅       | ✅   | -                                      | ✅   | Standard streaming.                               |
| **Assets/Files**       | ✅       | ✅   | -                                      | ✅   | Local storage & bundle support.                   |
| **AVI**                | ✅       | ❌   | -                                      | ✅   | Not supported on iOS (OS limitation).             |
| **WebM**               | ✅       | ❌   | ✅                                      | ✅   | **Requires WebView on iOS** (no native support); **seeking is disabled on iOS** (WebKit can't seek WebM without freezing). |

<br>

## ✨ Key Features

* 📦 **Universal Sources**: YouTube (Live/VOD), Vimeo, Network, Assets, and Local Files.
* ⚙️ **Quality Selector**: Built-in UI to switch resolutions for YouTube and HLS streams.
* 🎨 **Fully Skinnable**: Customize the UI, overlays, and controls to match your brand.
* ⏩ **Advanced UX**: Double-tap to seek, playback speed control (0.5x to 2.0x), and swipe gestures.
* 🔊 **Global Sync**: Synchronize volume and mute states across multiple player instances.
* ⛶ **Native Fullscreen**: Smooth transition to fullscreen mode on mobile.

<br>

## 🧪 Preview

<table border="0" cellpadding="0" cellspacing="0" align="center">
  <tr>
    <td align="center" style="padding: 10px;"><b>YouTube</b></td>
    <td align="center" style="padding: 10px;"><b>YouTube Live</b></td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/leonardmatasel/omni_video_player/blob/main/example/assets/yt_omni_video_player.gif?raw=true" height="400" alt="YouTube"/></td>
    <td align="center"><img src="https://github.com/leonardmatasel/omni_video_player/blob/main/example/assets/yt_live_omni_video_player.gif?raw=true" height="400" alt="YouTube Live"/></td>
  </tr>
  <tr>
    <td align="center" style="padding: 10px;"><b>M3U8 Network Link</b></td>
    <td align="center" style="padding: 10px;"><b>Vimeo</b></td>
  </tr>
  <tr>
    <td align="center"><img src="https://github.com/leonardmatasel/omni_video_player/blob/main/example/assets/m3u8_omni_video_player.gif?raw=true" height="400" alt="M3U8"/></td>
    <td align="center"><img src="https://github.com/leonardmatasel/omni_video_player/blob/main/example/assets/vimeo_omni_video_player.gif?raw=true" height="400" alt="Vimeo"/></td>
  </tr>
</table>

<br>

## 🛠️ Quick Start

### 1. Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  omni_video_player: ^latest_version

```

### 2. Platform Setup (Optional)

Configure these only if your use case requires it:

#### **Android** (`AndroidManifest.xml`)

* **INTERNET**: Required for any online stream (YouTube, Vimeo, Web).
* **Cleartext**: Required only for insecure `http` links.

```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/> <application android:usesCleartextTraffic="true"> ...
    </application>
</manifest>

```

#### **iOS** (`Info.plist`)

* **Arbitrary Loads**: Required only for insecure `http` links.

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key><true/> </dict>

```

> **Note:** If you use only `https` (standard for YouTube/Vimeo) and local assets, you can skip the Cleartext/Arbitrary Loads settings.

<br>

## 📦 Code Examples

### Standard Implementation

```dart
OmniVideoPlayer(
  sourceConfiguration: VideoSourceConfiguration.youtube(
    videoUrl: Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
    preferredQualities: [OmniVideoQuality.high720],
  ),
)

```

## 🕹️ Full Live Demo

Want to see the player in action with all its features? We have provided a comprehensive example project.

1. **Download/Clone** this repository.
2. Navigate to the `example/` folder.
3. Run `lib/main.dart` on your device or emulator.

This demo showcases **everything the library supports**: quality switching, source transitions, custom controls, and more. It is the best way to understand the full potential of **omni_video_player**.

<br>

### Reactive UI with Controller

Control the player from anywhere in your widget tree:

```dart
OmniPlaybackController? _controller;

// Listen to state changes (play/pause, buffering, etc.)
void _onUpdate() => setState(() {});

OmniVideoPlayer(
  callbacks: VideoPlayerCallbacks(
    onControllerCreated: (controller) {
      _controller = controller..addListener(_onUpdate);
    },
  ),
);

@override
void dispose() {
  _controller?.removeListener(_onUpdate);
  super.dispose();
}

```

<br>

### Playlist

Play an ordered queue of videos with on-video previous/next buttons. Set `autoAdvance` to move to the next video automatically when one finishes, and `loop` to wrap around the ends:

```dart
OmniVideoPlaylist(
  playlistConfiguration: PlaylistConfiguration(
    autoAdvance: true,
    loop: true,
    items: [
      VideoSourceConfiguration.youtube(
        videoUrl: Uri.parse('https://www.youtube.com/watch?v=djV11Xbc914'),
      ),
      VideoSourceConfiguration.youtube(
        videoUrl: Uri.parse('https://www.youtube.com/watch?v=Zi_XLOBDo_Y'),
      ),
      VideoSourceConfiguration.youtube(
        videoUrl: Uri.parse('https://www.youtube.com/watch?v=fJ9rUzIMcZQ'),
      ),
    ],
  ),
  playerConfiguration: VideoPlayerConfiguration(
    videoSourceConfiguration: VideoSourceConfiguration.youtube(
      videoUrl: Uri.parse('https://www.youtube.com/watch?v=djV11Xbc914'),
    ),
  ),
  callbacks: VideoPlayerCallbacks(),
  playlistCallbacks: PlaylistCallbacks(
    onVideoChanged: (index) => debugPrint('Playlist: now at $index'),
    onPlaylistCompleted: () => debugPrint('Playlist: completed'),
  ),
)

```

<br>

## 🔊 Multiple Players on Screen

Only one **audible** player plays at a time: starting an audible player pauses the audible one before it. Muted players sit outside that rule — any number of them play together, and unmuting one makes it join the rule, pausing whoever was audible at that moment. Muting a playing video releases it from the rule without stopping it.

A player holds the wakelock while it is **audible or fullscreen**, so a list of decorative muted loops does not keep the device awake, while a video you muted and kept watching full screen still does.

For a row or list of muted looping videos, set `autoPlay: true` and `autoMuteOnStart: true`, and leave `pauseWhenOutOfView` at its default: playback starts when the player is fully visible and stops when it scrolls away. `onFinished` fires once at the real end of every playback and re-arms afterwards, so it can drive a "play N times" counter.

A player given an explicit `initialVolume` keeps it. The shared volume no longer overwrites it when the player is created, and later changes to the shared volume still reach it unless `synchronizeMuteAcrossPlayers` is `false`. When both are set, `autoMuteOnStart` wins and `initialVolume` becomes the level the player returns to once unmuted.

<br>

## 🔮 Roadmap

| Feature | Description | Status |
| --- | --- | --- |
| **Picture-in-Picture** | Play in floating overlay (OS level). | 🏗️ Researching |
| **Playlist Support** | Queue system for multiple videos. | ✅ (4.0.0) |
| **Download Mode** | Cache management for offline viewing. | 🔜 Planned |
| **Cast Support** | Google Cast & AirPlay integration. | 🔜 Planned |

<br>

## ❓ FAQ

### Known Issue: "Made for Kids" YouTube Videos

Youtube videos marked as **"Made for Kids"** in YouTube Studio cannot be played using the default extraction method on mobile platforms (iOS/Android) due to API restrictions.

* **Solution 1:** If you own the video, uncheck the "Made for Kids" option in YouTube Studio.
* **Solution 2:** Initialize the player with `forceYoutubeWebViewOnly: true`. This bypasses the default extraction and plays the video via WebView.

### Why is there no quality selection for YouTube on iOS?

On Android, we can handle separate Audio and Video streams provided by the API, allowing for multiple quality options.

* **The iOS Limitation:** The native iOS player struggles to synchronize separate Audio/Video tracks without pre-loading the entire file (causing huge delays).
* **The Result:** On iOS, we must use a "muxed" stream (combined audio/video). The YouTube API currently provides only **one muxed stream at 360p**. Therefore, quality selection is disabled on iOS as there are no other combined streams available to switch to.

### Why can't I seek WebM videos on iOS?

WebM has no native iOS support, so it plays through a WebView. WebKit, however, cannot seek a WebM stream without freezing the decoder (the frame stalls and can't recover). To avoid a broken state, **seeking is disabled for WebM on iOS**: the seek bar and skip gestures are turned off, while play/pause and duration work normally. WebM seeking works on Android (native playback).

<br>

## 📄 License

Released under the **BSD 3-Clause License**. See [LICENSE](LICENSE) for details.

<br>

Built with ❤️ by [Leonard Matasel](https://github.com/leonardmatasel)
*Found a bug? Open an [issue](https://github.com/leonardmatasel/omni_video_player/issues) or submit a PR!*

