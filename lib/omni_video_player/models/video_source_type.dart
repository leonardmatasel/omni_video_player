/// Defines the available video source types for the player.
///
/// This enum is used to determine the appropriate handling and initialization
/// logic based on the origin and format of the video content.
///
/// ### Supported Sources
/// - [youtube] — Videos hosted on YouTube.
/// - [vimeo] — Videos from Vimeo.
/// - [twitch] — Twitch stream playback.
/// - [network] — Generic network-based video URLs (e.g., MP4 files).
/// - [asset] — Local asset files bundled with the application.
/// - [file] — Video files stored locally on the device.
///
enum VideoSourceType { youtube, vimeo, twitch, network, asset, file }
