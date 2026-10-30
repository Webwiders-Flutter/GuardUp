import 'package:share_plus/share_plus.dart';

// class ShareUtils {
//   /// Shares a video, including its title, description, and URL.
//   static void shareVideo(VideoEntity video) {
//     final String brandedLink =
//         '${EnvConfig.appDeepLinkBaseUrl}/video/${video.id}';
//     String shareText =
//         'Check out this awesome video on SKY VIORA:\n$brandedLink';
//     if (video.title.isNotEmpty) {
//       shareText = '${video.title}\n$shareText';
//     }
//     if (video.description.isNotEmpty) {
//       shareText = '$shareText\n\n${video.description}';
//     }
//     Share.share(shareText);
//   }
// }

class ShareUtils {
  static DateTime? _lastShareTime;

  /// Shares a video, including its title, description, and URL.
  static Future<void> shareVideo(ShareParams shareParams) async {
    final now = DateTime.now();

    // Prevent multiple taps within 2 seconds
    if (_lastShareTime != null &&
        now.difference(_lastShareTime!) < const Duration(milliseconds: 1200)) {
      return;
    }

    _lastShareTime = now;

    // Share a clean branded link using the skyviora.com domain.
    // When tapped on a phone with the app installed, it opens directly inside SKY VIORA.
    // When tapped on a computer or without the app, it shows a beautiful web page
    // where the video can be watched in the browser.
    // final String brandedLink =
    //     '${EnvConfig.appDeepLinkBaseUrl}/video/${video.id}'

    await SharePlus.instance.share(shareParams);
  }
}
