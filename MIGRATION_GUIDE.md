# 🧭 Migration Guide — 2.x.x → 3.0.0

Version **3.0.0** brings a major cleanup and internal refactor of `omni_video_player`.
The goal of this update is to simplify integration, reduce dependencies, and make playback behavior consistent out of the box.

## 🎬 1. Global Playback Is Now Built-In

**Before (old setup):**

```dart
void main() {
  runApp(
    BlocProvider(
      create: (_) => GlobalPlaybackController(),
      child: const MyApp(),
    ),
  );
}
```

**After (new setup):**

```dart
void main() {
  runApp(MyApp());
}
```

🎯 **What changed:**
The global playback management is now **integrated internally** — no extra controller or provider needed.
Videos still behave exactly the same: when a new video starts, any other playing video will automatically pause.

## ⚙️ 2. Remove Deprecated Global Settings

Remove any references to:

```dart
globalPlaybackControlSettings: GlobalPlaybackControlSettings(...),
```

and the following fields:

```dart
useGlobalPlaybackController
synchronizeMuteAcrossPlayers
```

If you used `synchronizeMuteAcrossPlayers`, it is now defined inside:

```dart
VideoSourceConfiguration(synchronizeMuteAcrossPlayers: true)
```



## 🧩 3. Update Error Placeholders

The following options have been removed from `PlayerUIVisibilityOptions`:

* `showRefreshButtonInErrorPlaceholder`
* `showOpenExternallyInErrorPlaceholder`

`VideoPlayerErrorPlaceholder` has also been simplified and no longer includes action buttons.
You can now pass your own widget to:

```dart
CustomPlayerWidgets.errorPlaceholder
```

💡 Example implementation: [Old Video Player Error Placeholder](https://github.com/leonardmatasel/omni_video_player/blob/main/example/lib/custom_widgets/video_player_error_placeholder.dart)



## 🧹 4. Dependencies Cleanup

We removed the following:

```yaml
flutter_bloc:
android_intent_plus:
url_launcher:
built_collection:
```

🎯 **Why:**
These are no longer required — the package is lighter, faster, and more focused.



## ⚠️ 5. Minimum Flutter & Dart Version

* **Flutter:** `>=3.35.0`
* **Dart:** `>=3.9.0 <4.0.0`

🎯 **Why:**
This version guarantees compatibility with the new core playback implementation and all updated dependencies.
Older Flutter versions may cause build errors on iOS or Android.



## 🔧 6. Clean Build Recommended

After updating, run:

```bash
flutter clean
flutter pub get
```



## ✅ You’re All Set

You’ve migrated to **omni_video_player 3.0.0** 🎉