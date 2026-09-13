import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Where the courier's own photo stands with the branch.
///
/// There is no backend, so the review never resolves in the demo: a photo the
/// courier uploads stays **pending** until the branch dashboard exists to
/// accept or decline it.
///
/// TODO(flutter-dev): when the backend lands, upload the bytes on [pick] and
/// listen for the review verdict (accepted → show the photo plainly,
/// declined → drop back to [ProfilePhotoStatus.none] with the reason).
enum ProfilePhotoStatus {
  /// No photo uploaded — the avatar shows the courier's initials.
  none,

  /// Uploaded and waiting for the branch to accept or decline it.
  pending,
}

/// The courier's profile photo: picking, in-memory display bytes, and the
/// review status.
///
/// Rides the Live Activity method channel like every other native need
/// (dialer, maps) — a picker plugin would put CocoaPods back into the iOS
/// build. The native side presents the out-of-process `PHPicker` (no
/// permission prompt), persists a downscaled JPEG in documents, and hands the
/// bytes back; on Android, on the web, or on a build without the channel every
/// call is a silent no-op, so the avatar simply stays initials there.
class ProfilePhoto extends ChangeNotifier {
  ProfilePhoto._() {
    _restore();
  }

  static final ProfilePhoto instance = ProfilePhoto._();

  static const MethodChannel _channel = MethodChannel(
    'orderbase/live_activity',
  );

  Uint8List? _bytes;

  /// The photo to draw in the avatar, when there is one.
  Uint8List? get bytes => _bytes;

  ProfilePhotoStatus get status =>
      _bytes == null ? ProfilePhotoStatus.none : ProfilePhotoStatus.pending;

  /// Reload the stored photo after a relaunch (best-effort, silent).
  Future<void> _restore() async {
    if (kIsWeb) return;
    try {
      final data = await _channel.invokeMethod<Uint8List>('profilePhoto');
      if (data == null || data.isEmpty) return;
      _bytes = data;
      notifyListeners();
    } on MissingPluginException {
      // No native side (Android / web / pre-channel build).
    } on PlatformException {
      // Unreadable file; the initials avatar is fine.
    }
  }

  /// Opens the system photo picker. Returns true when a new photo was taken
  /// on — it is then [ProfilePhotoStatus.pending] and the caller should tell
  /// the courier the review is underway.
  Future<bool> pick() async {
    if (kIsWeb) return false;
    try {
      final data = await _channel.invokeMethod<Uint8List>('pickPhoto');
      if (data == null || data.isEmpty) return false;
      _bytes = data;
      notifyListeners();
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
