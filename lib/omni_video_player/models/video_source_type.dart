/// Defines the available video source types for the player.
///
/// This enum is used to determine the appropriate handling and initialization
/// logic based on the origin and format of the video content.
///
/// ### Supported Sources
/// - [youtube] — Videos hosted on YouTube.
/// - [vimeo] — Videos from Vimeo.
/// - [network] — Generic network-based video URLs (e.g., MP4 files).
/// - [asset] — Local asset files bundled with the application.
///
/// ### Planned Support
/// - [twitch] — *(Planned)* Twitch stream playback.
/// - [tiktok] — *(Planned)* TikTok video playback.
/// - [dailymotion] — *(Planned)* Dailymotion videos.
/// - [streamable] — *(Planned)* Streamable-hosted videos.
///
enum VideoSourceType { youtube, vimeo, network, asset }
