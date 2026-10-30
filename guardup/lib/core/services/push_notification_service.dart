import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:guardup/core/constants/app_colors.dart';
import 'package:guardup/core/constants/notification_type.dart';
import 'package:guardup/core/utils/app_logs.dart';
import 'package:guardup/core/utils/app_router.dart';
import 'package:guardup/core/utils/deep_link_handler.dart';
import 'package:guardup/features/auth/domain/repositories/auth_repository.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogs.info("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final AuthRepository _authRepository;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  PushNotificationService(this._authRepository);

  Future<void> init() async {
    try {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request permissions for iOS
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogs.info('User granted permission: ${settings.authorizationStatus}');

      // Set presentation options for foreground notifications on iOS.
      // iOS natively handles foreground banner presentation when alert: true is set.
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize Local Notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_notification');
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true,
          );
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            _handleNotificationNavigation(jsonDecode(response.payload!));
          }
        },
      );

      // Create Android Notification Channel with badging explicitly enabled
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Get the APNS token for iOS
      if (Platform.isIOS) {
        String? apnsToken = await _fcm.getAPNSToken();
        AppLogs.info("APNS Token: $apnsToken");
      }

      // Get the FCM token
      String? token = await _fcm.getToken();
      if (token != null) {
        AppLogs.info("FCM Token: $token");
        await _saveTokenToDatabase(token);
      }

      // Listen to token refreshes
      _fcm.onTokenRefresh.listen(_saveTokenToDatabase);

      // Listen to foreground messages.
      // On Android, we invoke _showLocalNotification since Android does not display foreground FCM banners natively.
      // On iOS, native presentation options present the banner automatically, so we do NOT call _showLocalNotification to prevent duplicate banners.
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogs.info('Got a message whilst in the foreground!');
        if (Platform.isAndroid) {
          _showLocalNotification(message);
        }
      });

      // Handle notification opened when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogs.info('A new onMessageOpenedApp event was published!');
        _handleNotificationNavigation(message.data);
      });

      // Check if app was opened via notification from terminated state
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationNavigation(initialMessage.data);
        });
      }
    } catch (e) {
      AppLogs.error("Error initializing push notifications", error: e);
    }
  }

  void _showLocalNotification(RemoteMessage message) async {
    String? title;
    String? body;

    if (message.notification != null) {
      title = message.notification!.title;
      body = message.notification!.body;
    } else if (message.data.containsKey('title') ||
        message.data.containsKey('body')) {
      title = message.data['title']?.toString();
      body = message.data['body']?.toString();
    }

    if (title != null || body != null) {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        icon: '@drawable/ic_notification',
        color: AppColors.primary,
        importance: Importance.max,
        priority: Priority.high,
        channelShowBadge: true,
        number: 1,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final context = AppRouter.rootNavigatorKey.currentContext;
    if (context == null) return;

    // 1. Direct deep link
    if (data.containsKey('deep_link')) {
      final deepLink = data['deep_link']?.toString();
      if (deepLink != null && deepLink.isNotEmpty) {
        DeepLinkHandler.handle(context, deepLink);
        return;
      }
    }

    // 2. Ticket ID check
    if (data.containsKey('ticketId') || data.containsKey('ticket_id')) {
      final ticketId = data['ticketId'] ?? data['ticket_id'];
      if (ticketId != null && ticketId.toString().isNotEmpty) {
        DeepLinkHandler.handle(context, 'skyviora://ticket/$ticketId');
        return;
      }
    }

    // 7. Other Notification Type routing
    final typeString = data['type']?.toString();
    if (typeString != null) {
      final type = NotificationType.fromString(typeString);

      switch (type) {
        case NotificationType.supportTicket:
        case NotificationType.ticket:
          final ticketId = data['ticketId'] ?? data['ticket_id'] ?? data['id'];
          if (ticketId != null && ticketId.toString().isNotEmpty) {
            DeepLinkHandler.handle(context, 'skyviora://ticket/$ticketId');
          } else {
            context.pushNamed(AppRouter.myTickets);
          }
          break;

        case NotificationType.general:
          final targetUrl = data['url'] ?? data['link'];
          if (targetUrl != null && targetUrl.toString().isNotEmpty) {
            DeepLinkHandler.handle(context, targetUrl.toString());
          }
          break;
        case NotificationType.unknown:
          break;
      }
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      if (_authRepository.currentUser != null) {
        await _authRepository.saveDeviceToken(token);
      }
    } catch (e, stackTrace) {
      AppLogs.error("Error saving FCM token", error: e, stackTrace: stackTrace);
    }
  }

  Future<void> removeTokenFromDatabase() async {
    try {
      final token = await _fcm.getToken();
      if (token != null && _authRepository.currentUser != null) {
        await _authRepository.removeDeviceToken(token);
      }
    } catch (e, stackTrace) {
      AppLogs.error(
        "Error removing FCM token",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> clearBadgeAndNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e, stackTrace) {
      AppLogs.error(
        "Error clearing notifications and badge",
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
