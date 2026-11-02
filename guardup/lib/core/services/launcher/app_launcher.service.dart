// ignore_for_file: use_null_aware_elements
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '/core/extensions/string.extension.dart';

final class AppLauncher {
  AppLauncher._();

  // =========================================================
  // CORE
  // =========================================================

  static Future<bool> launchUrlString(
    String url, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      final uri = Uri.parse(url);

      if (kIsWeb) {
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: mode);
      }

      return await launchUrl(uri, mode: mode);
    } catch (_) {
      try {
        return await launchUrl(Uri.parse(url));
      } catch (_) {
        return false;
      }
    }
  }

  static Future<bool> launchFile(
    String filePath, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    try {
      if (kIsWeb || filePath.isUrl) {
        return await launchUrlString(filePath, mode: mode);
      }

      final uri = Uri.file(filePath);

      final launched = await launchUrl(uri, mode: mode);
      if (launched) return true;

      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      try {
        final uri = Uri.file(filePath);
        return await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        try {
          return await launchUrlString(filePath, mode: mode);
        } catch (_) {
          return false;
        }
      }
    }
  }

  // =========================================================
  // WEB
  // =========================================================

  static Future<bool> openWebsite(String url) async {
    final formatted = url.startsWith('http') ? url : 'https://$url';

    return launchUrlString(formatted, mode: LaunchMode.externalApplication);
  }

  // =========================================================
  // EMAIL
  // =========================================================

  static Future<bool> sendEmail({
    required String email,
    String? subject,
    String? body,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email.isEmpty ? null : email,
      queryParameters: {
        if (subject != null) 'subject': subject,
        if (body != null) 'body': body,
      },
    );

    return launchUrl(uri);
  }

  // =========================================================
  // PHONE
  // =========================================================

  static Future<bool> callPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);

    return launchUrl(uri);
  }

  // =========================================================
  // SMS
  // =========================================================

  static Future<bool> sendSms(String phoneNumber, {String? message}) async {
    final uri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: {if (message != null) 'body': message},
    );

    return launchUrl(uri);
  }

  // =========================================================
  // WHATSAPP
  // =========================================================

  static Future<bool> openWhatsApp({
    required String phone,
    String? message,
  }) async {
    final encodedMessage = Uri.encodeComponent(message ?? '');

    final url = 'https://wa.me/$phone?text=$encodedMessage';

    return openWebsite(url);
  }

  // =========================================================
  // MAPS
  // =========================================================

  static Future<bool> openMaps({
    required double latitude,
    required double longitude,
  }) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    return openWebsite(url);
  }
}
