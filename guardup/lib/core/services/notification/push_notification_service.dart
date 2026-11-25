import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '/core/config/config.dart';
import '/core/logger/app_logger.dart';
import '/firebase_options.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler required by FirebaseMessaging.
/// Must be annotated with `@pragma('vm:entry-point')` so Flutter's isolate engine
/// does not strip it out during tree-shaking.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Platform-specific configuration might already be initialized natively.
  }

  AppLogger.d(
    'FCM Background message received: '
    'id=${message.messageId}, '
    'title=${message.notification?.title}, '
    'data=${message.data}',
    tag: 'PushNotificationService',
  );
}

/// Robust, production-grade service for Firebase Cloud Messaging (FCM)
/// and local foreground push notifications.
final class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description:
            'This channel is used for important transport and order alerts.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

  static final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  static final StreamController<Map<String, dynamic>>
  _notificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();

  static final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  static String? _cachedToken;

  /// Stream of incoming foreground FCM messages.
  static Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundMessageController.stream;

  /// Stream of notification payload taps (foreground, background, or terminated).
  static Stream<Map<String, dynamic>> get onNotificationTap =>
      _notificationTapController.stream;

  /// Stream emitting new FCM device tokens upon registration or rotation.
  static Stream<String> get onRegistered => _tokenRefreshController.stream;

  /// Backwards compatibility stream for [onRegistered].
  static Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  /// Returns current cached device token if already obtained.
  static String? get currentToken => _cachedToken;

  static bool _isInitialized = false;

  /// Returns true if notification permission is authorized.
  static Future<bool> get isNotificationAuthorized async {
    return _messaging.getNotificationSettings().then(
      (value) => value.authorizationStatus == AuthorizationStatus.authorized,
    );
  }

  /// Initializes push notifications, requests permission, and wires up message listeners.
  ///
  /// [onNotificationTapped] is an optional direct callback for routing when a notification is tapped.
  static Future<void> init({
    void Function(Map<String, dynamic> data)? onNotificationTapped,
  }) async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Initialize local notification display for Android & iOS foreground HUD
      // 4. Request notification permissions from OS (mobile only; Web requires a user gesture)
      if (!kIsWeb) {
        await _initializeLocalNotifications(onNotificationTapped);
        await requestPermission();
      }

      // 5. Configure iOS foreground presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      // 6. Listen to foreground FCM messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.d(
          'Foreground message received: id=${message.messageId}, data=${message.data}',
          tag: 'PushNotificationService',
        );
        _foregroundMessageController.add(message);
        // if (!kIsWeb) {
        //   _showForegroundLocalNotification(message);
        // }
      });

      // 7. Handle notification tap when app is brought to foreground from background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.d(
          'Notification tapped from background state: id=${message.messageId}, data=${message.data}',
          tag: 'PushNotificationService',
        );
        _handleNotificationTap(message.data, onNotificationTapped);
      });

      // 8. Handle notification tap when app was completely terminated
      final RemoteMessage? initialMessage = await _messaging
          .getInitialMessage();
      if (initialMessage != null) {
        AppLogger.d(
          'App opened from terminated state via notification: id=${initialMessage.messageId}, data=${initialMessage.data}',
          tag: 'PushNotificationService',
        );
        _handleNotificationTap(initialMessage.data, onNotificationTapped);
      }

      // 9. Listen for FCM token registration & refresh events
      _messaging.onRegistered.listen((String newToken) {
        AppLogger.d(
          'FCM token registered / refreshed: $newToken',
          tag: 'PushNotificationService',
        );
        _cachedToken = newToken;
        _tokenRefreshController.add(newToken);
      });

      _isInitialized = true;
    } catch (e, st) {
      AppLogger.e(
        'Failed to initialize PushNotificationService: $e',
        error: e,
        stackTrace: st,
        tag: 'PushNotificationService',
      );
    }
  }

  /// Sets up local notifications plugin for foreground display and taps.
  static Future<void> _initializeLocalNotifications(
    void Function(Map<String, dynamic> data)? onNotificationTapped,
  ) async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            _handleNotificationTap(data, onNotificationTapped);
          } catch (e) {
            AppLogger.w(
              'Failed to parse local notification payload: $e',
              tag: 'PushNotificationService',
            );
            _handleNotificationTap({'payload': payload}, onNotificationTapped);
          }
        }
      },
    );

    // Create high importance notification channel on Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_defaultChannel);
    }
  }

  /// Displays a heads-up banner when a push arrives while app is in foreground.
  // static Future<void> _showForegroundLocalNotification(
  //   RemoteMessage message,
  // ) async {
  //   final notification = message.notification;
  //   final title = notification?.title ?? message.data['title']?.toString();
  //   final body = notification?.body ?? message.data['body']?.toString();

  //   // If there is no title or body, no banner needs to be shown
  //   if (title == null && body == null) return;

  //   final androidDetails = AndroidNotificationDetails(
  //     _defaultChannel.id,
  //     _defaultChannel.name,
  //     channelDescription: _defaultChannel.description,
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     icon: '@mipmap/ic_launcher',
  //   );

  //   const darwinDetails = DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //   );

  //   final platformDetails = NotificationDetails(
  //     android: androidDetails,
  //     iOS: darwinDetails,
  //   );

  //   final notificationId = message.messageId.hashCode;

  //   await _localNotifications.show(
  //     id: notificationId,
  //     title: title,
  //     body: body,
  //     notificationDetails: platformDetails,
  //     payload: jsonEncode(message.data),
  //   );
  // }

  /// A tap that arrived before anything listened to [onNotificationTap]
  /// (the notification that launched the app: [init] runs before the UI).
  static Map<String, dynamic>? _pendingTap;

  /// Returns (and clears) the tap that arrived before anyone listened.
  static Map<String, dynamic>? takePendingTap() {
    final tap = _pendingTap;
    _pendingTap = null;
    return tap;
  }

  /// Dispatches the tapped notification data to both stream listeners and the callback.
  static void _handleNotificationTap(
    Map<String, dynamic> data,
    void Function(Map<String, dynamic> data)? callback,
  ) {
    if (_notificationTapController.hasListener) {
      _notificationTapController.add(data);
    } else {
      _pendingTap = data;
    }
    callback?.call(data);
  }

  /// Requests notification permission from user and returns authorization status.
  static Future<NotificationSettings?> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      AppLogger.d(
        'Notification permission status: ${settings.authorizationStatus}',
        tag: 'PushNotificationService',
      );
      return settings;
    } catch (e, st) {
      AppLogger.e(
        'Failed to request notification permission: $e',
        error: e,
        stackTrace: st,
        tag: 'PushNotificationService',
      );
      return null;
    }
  }

  /// Retrieves the current device FCM token safely.
  /// On Web, ensures permission is authorized first to avoid Safari user gesture errors.
  /// On iOS, gracefully awaits APNS registration first to avoid crashes.
  static Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        final settings = await _messaging.getNotificationSettings();
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          AppLogger.w(
            'Web notification permission not granted (${settings.authorizationStatus}). Web requires user gesture to prompt before getToken.',
            tag: 'PushNotificationService',
          );
          return null;
        }
      }

      if (!kIsWeb && Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          AppLogger.w(
            'APNS token not yet available. Retrying FCM token acquisition...',
            tag: 'PushNotificationService',
          );
          // Briefly wait if APNS is registering
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      String? vapidKey;
      if (kIsWeb) {
        final rawKey = AppEnvironment.config.firebaseVapidKey.trim();
        if (rawKey.isNotEmpty && !rawKey.toLowerCase().contains('dummy')) {
          vapidKey = rawKey;
        } else {
          AppLogger.w(
            'FCM Web VAPID key is not configured or is a placeholder ("$rawKey"). Skipping Web Push token retrieval.',
            tag: 'PushNotificationService',
          );
          return null;
        }
      }

      // If a cached token is already available from onRegistered, return it
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        return _cachedToken;
      }

      // Register device instance with FCM (replaces deprecated getToken)
      final completer = Completer<String?>();
      final sub = _messaging.onRegistered.listen((t) {
        if (!completer.isCompleted) completer.complete(t);
      });

      try {
        try {
          await _messaging.register(vapidKey: vapidKey);
          final token = await completer.future.timeout(
            const Duration(seconds: 4),
            onTimeout: () => null,
          );
          if (token != null && token.isNotEmpty) {
            _cachedToken = token;
            AppLogger.d("FCM Token: $token");
            return token;
          }
        } catch (regError) {
          AppLogger.w(
            'FCM register() skipped or failed: $regError, falling back to direct token fetch',
            tag: 'PushNotificationService',
          );
        }
      } finally {
        await sub.cancel();
      }

      // Fallback for platform edge cases if onRegistered did not emit within timeout
      // ignore: deprecated_member_use
      final fallbackToken = await _messaging.getToken(vapidKey: vapidKey);
      if (fallbackToken != null) {
        _cachedToken = fallbackToken;
      }
      AppLogger.d("FCM Token: $_cachedToken");
      return _cachedToken;
    } catch (e, st) {
      AppLogger.e(
        'Error retrieving FCM token: $e',
        error: e,
        stackTrace: st,
        tag: 'PushNotificationService',
      );
      return null;
    }
  }

  /// Unregisters the current device from FCM (replaces deprecated deleteToken).
  static Future<void> deleteToken() async {
    try {
      await _messaging.unregister();
      _cachedToken = null;
      AppLogger.d(
        'FCM token unregistered successfully.',
        tag: 'PushNotificationService',
      );
    } catch (e, st) {
      AppLogger.e(
        'Failed to unregister FCM token: $e',
        error: e,
        stackTrace: st,
        tag: 'PushNotificationService',
      );
    }
  }

  /// Modern alias for [deleteToken].
  static Future<void> unregister() => deleteToken();

  /// Subscribes current device to a specific topic (e.g. 'all_transporters').
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.d(
        'Subscribed to topic: $topic',
        tag: 'PushNotificationService',
      );
    } catch (e, st) {
      AppLogger.e(
        'Failed to subscribe to topic "$topic": $e',
        error: e,
        stackTrace: st,
        tag: 'PushNotificationService',
      );
    }
  }

  /// Unsubscribes current device from a topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.d(
        'Unsubscribed from topic: $topic',
        tag: 'PushNotificationService',
      );
    } catch (e, st) {
      AppLogger.e(
        'Failed to unsubscribe from topic "$topic": $e',
        error: e,
        stackTrace: st,
        tag: 'PushNotificationService',
      );
    }
  }

  /// Clears all displayed local notifications from notification drawer.
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
