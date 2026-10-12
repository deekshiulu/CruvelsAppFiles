import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level background message handler - MUST be top-level and annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized or waiting for config
  }
  developer.log('Handling background message: ${message.messageId}', name: 'FCM');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    try {
      // Initialize Firebase app
      await Firebase.initializeApp();

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Setup local notifications for Android foreground notification banners
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(settings: initSettings);

      // Create Android Notification Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Listen for foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                importance: Importance.high,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });

      // Request permissions and retrieve FCM token
      await requestPermission();
    } catch (e) {
      developer.log(
        'Firebase not initialized yet. Ensure google-services.json is added to android/app/. Error: $e',
        name: 'NotificationService',
      );
    }
  }

  static Future<String?> requestPermission() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Native OS permission pop-up
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      developer.log(
        'User permission status: ${settings.authorizationStatus}',
        name: 'FCM',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? token = await messaging.getToken();
        developer.log('=====================================', name: 'FCM');
        developer.log('FCM Device Token: $token', name: 'FCM');
        developer.log('Send this token to your backend/Next.js API', name: 'FCM');
        developer.log('=====================================', name: 'FCM');

        // Listen for token refreshes
        messaging.onTokenRefresh.listen((newToken) {
          developer.log('FCM Token Refreshed: $newToken', name: 'FCM');
        });

        return token;
      }
    } catch (e) {
      developer.log('Failed to request notification permission: $e', name: 'FCM');
    }
    return null;
  }
}
