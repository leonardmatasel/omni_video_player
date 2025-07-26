
<h1 align="center">
  <img src="https://github.com/leonardmatasel/omni_video_player/blob/main/example/assets/logo_horizontal.png?raw=true" alt="omni_video_player" height="125"/>
</h1>

<p align="center">
  <strong>All-in-one Flutter video player – stream from YouTube, Vimeo, network, assets files</strong>
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


## Introduction

**omni\_video\_player** is a Flutter video player built on top of Flutter’s official `video_player` plugin. It supports YouTube (via `youtube_explode_dart`), Vimeo videos (using `flutter_inappwebview`), as well as network and asset videos. A single unified controller is provided to manage playback across all supported video types seamlessly.


🎨 Highly customizable — tweak UI, show/hide controls, and easily integrate your own widgets.  
🎮 The controller gives full control over video state and callbacks for smooth video management on mobile and web.

🎯 **Long-term goal:** to create a universal, flexible, and feature-rich video player that works flawlessly across all platforms and video sources, empowering developers with maximum control and customization options.

<br>

## Supported Platforms & Status

| Video Source Type | Android | iOS  |  Web  | Status        |
|-------------------|---------|------|-------|---------------|
| YouTube           |   ✅    |  ✅  |  ❌   | ✅ Supported  |
| Vimeo             |   ✅    |  ✅  |  ❌   | ✅ Supported  |
| Network           |   ✅    |  ✅  |  ✅   | ✅ Supported  |
| Asset             |   ✅    |  ✅  |  ✅   | ✅ Supported  |
| Twitch            |   -    |  -   |   -   | 🔜 Planned    |
| TikTok            |   -    |  -   |   -   | 🔜 Planned    |
| Dailymotion       |   -    |  -   |   -   | 🔜 Planned    |


<br>

## ✨ Features

- ✅ Play videos from:
  - YouTube (support for live and regular videos)
  - Vimeo (public)
  - Network video URLs
  - Flutter app assets
- 🎛 Customizable player UI (controls, theme, overlays, labels)
- 🔁 Autoplay, replay, mute/unmute, volume control
- ⏪ Seek bar & scrubbing
- 🖼 Thumbnail support (custom or auto-generated for YouTube and Vimeo)
- 🔊 Global playback & mute sync across players
- ⛶ Fullscreen player
- ⚙️ Custom error and loading widgets
- 🎚️ Quality selection UI:
  - Supports **YouTube quality switching**
  - Supports **HLS/network stream quality switching**

<br>

## 🧪 Demo

<p align="center">
  <img src="https://github.com/leonardmatasel/omni_video_player/blob/main/example/assets/showcase.gif?raw=true" width="300"/>
</p>

## 🚀 Getting Started

### Installation

Check the latest version on: [![Pub Version](https://img.shields.io/pub/v/omni_video_player.svg)](https://pub.dev/packages/omni_video_player)

```yaml
dependencies:
  omni_video_player: <latest_version>
````


---

### 🛠️ Android Setup

In your Flutter project, open:

```
android/app/src/main/AndroidManifest.xml
```

```xml
<!-- Add inside <manifest> -->
<uses-permission android:name="android.permission.INTERNET"/>

<!-- Add inside <application> -->
<application
    android:usesCleartextTraffic="true"
    ... >
</application>
```

✅ The `INTERNET` permission is required for streaming videos.


⚠️ The `usesCleartextTraffic="true"` is only needed if you're using HTTP (not HTTPS) URLs.

---

### 🍎 iOS Setup

To allow video streaming over HTTP (especially for development or non-HTTPS sources), add the following to your `Info.plist` file:

```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

<br>


## 📦 Usage Examples

### Network

```dart
VideoSourceConfiguration.network(
  videoUrl: Uri.parse('https://example.com/video.mp4'),
);
```

### YouTube

```dart
VideoSourceConfiguration.youtube(
  videoUrl: Uri.parse('https://youtu.be/xyz'),
  preferredQualities: [OmniVideoQuality.high720, OmniVideoQuality.low144],
);
```

### Vimeo

```dart
VideoSourceConfiguration.vimeo(
  videoId: '123456789',
  preferredQualities: [OmniVideoQuality.high720],
);
```

### Asset

```dart
VideoSourceConfiguration.asset(
  videoDataSource: 'assets/video.mp4'),
);
```

<br>

## 📱 Example App

Explore the [`example/`](https://github.com/leonardmatasel/omni_video_player/tree/main/example) folder for working demos:

* **Full demo** using different video sources: [`main.dart`](https://github.com/leonardmatasel/omni_video_player/blob/main/example/lib/main.dart)
* **Minimal setup** with controller and play/pause logic: [`example.dart`](https://github.com/leonardmatasel/omni_video_player/blob/main/example/lib/example.dart)

> 💡 Great starting points to understand how to integrate and customize the player.

<br>

## 🎯 Sync UI with `AnimatedBuilder`

When using `OmniPlaybackController`, the controller itself is a `Listenable`, meaning it **notifies listeners** when playback state changes (e.g. play, pause, fullscreen).

To build dynamic UI that reacts to those changes (like updating a play/pause button), wrap your widgets with `AnimatedBuilder`:

```dart
OmniVideoPlayer(
  options: VideoPlayerConfiguration.youtube(
    videoUrl: Uri.parse('https://www.youtube.com/watch?v=cuqZPx0H7a0'),
  ),
  callbacks: VideoPlayerCallbacks(
    onControllerCreated: (controller) {
      _controller = controller;
      setState(() {}); // Enables the button below
    },
  ),
),
```
```dart
AnimatedBuilder(
  animation: Listenable.merge([controller]),
  builder: (context, _) {
    if (controller == null) return const CircularProgressIndicator();

    final isPlaying = controller.isPlaying;

    return ElevatedButton.icon(
      onPressed: () =>
          isPlaying ? controller.pause() : controller.play(),
      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
      label: Text(isPlaying ? 'Pause' : 'Play'),
    );
  },
);
```

### ✅ Why it's needed

Flutter widgets **don’t rebuild** on `Listenable` changes by default. `AnimatedBuilder` lets your UI stay in sync without manually calling `setState()` on every controller update — making your code more efficient and reactive.

> ℹ️ Recommended for **any** UI that depends on the controller (playback state, fullscreen, etc.). It ensures consistent behavior and avoids state mismatch.


<br>



## 🔮 Future Developments

| Feature                      | Description                                                                 | Implemented              |
|-----------------------------|-----------------------------------------------------------------------------|--------------------------|
| 📃 Playlist Support         | YouTube playlist playback and custom video URL lists                        | ❌                        |
| ⏩ Double Tap Seek           | Skip forward/backward by configurable duration                              | ✅                        |
| 📚 Side Command Bars        | Left and right customizable sidebars for placing user-defined widgets or controls | ❌                        |
| 🧭 Header Bar               | Custom header with title, channel info, and actions                         | ❌                        |
| 🖼 Picture-in-Picture (PiP) | Play video in floating overlay while multitasking                           | ❌                        |
| 📶 Quality Selection        | Switch between 360p, 720p, 1080p, etc. during playback                      | ✅ (YouTube, Network HLS) |
| ⏱ Playback Speed Control   | Adjust speed: 0.5x, 1.5x, 2x, etc.                                           | ❌                        |
| 🔁 Looping / Repeat         | Loop a single video or an entire playlist                                   | ❌                        |
| ♿ Accessibility             | Screen reader support, keyboard nav, captions, ARIA, high contrast, etc.   | ❌                        |
| ⬇️ Download / Offline Mode | Save videos temporarily for offline playback                                | ❌                        |
| 📺 Chromecast & AirPlay     | Stream to external devices like TVs or smart displays                       | ❌                        |
| 🔒 Parental Controls        | Restrict age-inappropriate or sensitive content                             | ❌                        |
| ⚙️ Settings Button          | Easily access and configure playback preferences                            | ❌                        |
| 👉 Swipe to Exit Fullscreen | Swipe down (or specific gesture) to exit fullscreen mode                    | ✅                        |



<br>

## 📄 License

BSD 3-Clause License – see [LICENSE](LICENSE)
