import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:guardup/core/utils/app_logs.dart';

class HlsManifestParser {
  static Future<Map<String, String>> getResolutions(
    String masterPlaylistUrl,
    Dio dio,
  ) async {
    final Map<String, String> resolutions = {'Auto': masterPlaylistUrl};
    try {
      final response = await dio.get(
        masterPlaylistUrl,
        options: Options(
          headers: {
            'User-Agent': 'SkyVioraApp/1.0',
            'Referer': 'https://skyviora.com',
            'Origin': 'https://skyviora.com',
          },
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final String body = response.data.toString();
        final lines = const LineSplitter().convert(body);
        String? currentResolution;

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.startsWith('#EXT-X-STREAM-INF:')) {
            // Extract NAME="720p" first (prefer explicit naming from server)
            final nameMatch = RegExp(r'NAME="([^"]+)"').firstMatch(line);
            if (nameMatch != null &&
                (nameMatch.group(1)!.endsWith('p') ||
                    nameMatch.group(1) == 'Auto')) {
              currentResolution = nameMatch.group(1);
            } else {
              // Fallback to calculating from RESOLUTION=1280x720
              final resolutionMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)')
                  .firstMatch(line);
              if (resolutionMatch != null) {
                final width = int.parse(resolutionMatch.group(1)!);
                final height = int.parse(resolutionMatch.group(2)!);
                final maxDim = width > height ? width : height;
                final minDim = width < height ? width : height;

                if (width == 1080 ||
                    height == 1080 ||
                    width == 1920 ||
                    height == 1920) {
                  currentResolution = '1080p';
                } else if (width == 720 ||
                    height == 720 ||
                    width == 1280 ||
                    height == 1280) {
                  currentResolution = '720p';
                } else if (width == 480 ||
                    height == 480 ||
                    width == 854 ||
                    height == 854) {
                  currentResolution = '480p';
                } else if (width == 360 ||
                    height == 360 ||
                    width == 640 ||
                    height == 640) {
                  currentResolution = '360p';
                } else {
                  // Fallback for non-standard resolutions
                  if (maxDim >= 1920 || minDim >= 1080) {
                    currentResolution = '1080p';
                  } else if (maxDim >= 1280 || minDim >= 720) {
                    currentResolution = '720p';
                  } else if (maxDim >= 854 || minDim >= 480) {
                    currentResolution = '480p';
                  } else {
                    currentResolution = '360p';
                  }
                }
              }
            }
          } else if (line.isNotEmpty && !line.startsWith('#')) {
            // This line is the URL for the resolution
            String url = line;

            // If currentResolution is still null, try extracting from URL folder (e.g. stream_1080p)
            if (currentResolution == null) {
              if (url.contains('1080p')) {
                currentResolution = '1080p';
              } else if (url.contains('720p')) {
                currentResolution = '720p';
              } else if (url.contains('480p')) {
                currentResolution = '480p';
              } else if (url.contains('360p')) {
                currentResolution = '360p';
              } else {
                currentResolution = 'Auto';
              }
            }
            if (!url.startsWith('http')) {
              // Handle relative URLs
              final uri = Uri.parse(masterPlaylistUrl);
              url = uri.resolve(url).toString();
            }
            resolutions[currentResolution] = url;
            currentResolution = null;
          }
        }
      } else {
        AppLogs.error(
          'Failed to load m3u8 manifest: ${response.statusCode} - ${response.data}',
        );
      }
    } catch (e) {
      AppLogs.error('Error parsing m3u8 manifest', error: e);
    }
    return resolutions;
  }
}
