# omni_video_player

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

---

## 🚀 Why Omni Video Player?

Stop juggling multiple packages for different video sources. **omni_video_player** wraps the complexity of specialized extractors and webviews into a **single, powerful widget**.

* **Smart YouTube Handling**: Direct extraction via `youtube_explode_dart` with an **automatic WebView fallback**. If YouTube rate-limits your app, the player switches to WebView seamlessly—no black screens for your users.
* **Vimeo Ready**: Stable playback using optimized WebViews.
* **Adaptive Streaming**: Native support for **HLS (.m3u8)** with built-in **quality selection** UI.
* **Unified Controller**: One controller to rule them all. Manage state, volume, and seeking regardless of the source.

---

## 📊 Compatibility Matrix

| Source / Format        | Android | iOS | WebView | Web | Notes                                            |
|------------------------|---------|-----|---------|-----|--------------------------------------------------|
| **YouTube**            | ✅       | ✅   | ✅       | ✅   | Auto-fallback to WebView on rate-limit.          |
| **Vimeo**              | ❌       | ❌   | ✅       | ❌   | High stability via WebView.                      |
| **HLS (.m3u8)**        | ✅       | ✅   | ❌       | ✅   | **Multi-quality switching** supported.           |
| **Network (.mp4/etc)** | ✅       | ✅   | ❌       | ✅   | Standard streaming.                              |
| **Assets/Files**       | ✅       | ✅   | ❌       | ✅   | Local storage & bundle support.                  |
| **AVI**                | ✅       | ❌   | ❌       | ✅   | Not supported on iOS (OS limitation).            |
| **WebM**               | ✅       | ❌   | ✅       | ✅   | **Requires WebView on iOS** (no native support). |
| **Twitch**             | -       | -   | -       | -   | 🔜 Coming Soon.                                  |

---

## ✨ Key Features

* 📦 **Universal Sources**: YouTube (Live/VOD), Vimeo, Network, Assets, and Local Files.
* ⚙️ **Quality Selector**: Built-in UI to switch resolutions for YouTube and HLS streams.
* 🎨 **Fully Skinnable**: Customize the UI, overlays, and controls to match your brand.
* ⏩ **Advanced UX**: Double-tap to seek, playback speed control (0.5x to 2.0x), and swipe gestures.
* 🔊 **Global Sync**: Synchronize volume and mute states across multiple player instances.
* ⛶ **Native Fullscreen**: Smooth transition to fullscreen mode on mobile.

---

## 🧪 Preview

<p align="center">
<img src="[https://github.com/leonardmatasel/omni_video_player/blob/main/example/assets/showcase.gif?raw=true](https://github.com/leonardmatasel/omni_video_player/blob/main/example/assets/showcase.gif?raw=true)" width="320" style="border-radius: 20px"/>
</p>

---

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

---

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

---

## 🔮 Roadmap

| Feature | Description | Status |
| --- | --- | --- |
| **Picture-in-Picture** | Play in floating overlay (OS level). | 🏗️ Researching |
| **Playlist Support** | Queue system for multiple videos. | 🔜 Planned |
| **Download Mode** | Cache management for offline viewing. | 🔜 Planned |
| **Cast Support** | Google Cast & AirPlay integration. | 🔜 Planned |

---

## 📄 License

Released under the **BSD 3-Clause License**. See [LICENSE](LICENSE) for details.

---

**Built with ❤️ by [**Leonard Matasel**](https://github.com/leonardmatasel)
*Found a bug? Open an [issue](https://github.com/leonardmatasel/omni_video_player/issues) or submit a PR!*
