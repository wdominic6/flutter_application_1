import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
}

class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'garage_sale_alerts',
        'Garage Sale',
        description: 'Alertas importantes de Garage Sale App',
        importance: Importance.high,
      );

  static Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      linux: LinuxInitializationSettings(defaultActionName: 'Abrir'),
    );

    await _localNotifications.initialize(initializationSettings);
    await _createAndroidChannel();
    await requestPermissions();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundMessage);
  }

  static Future<void> requestPermissions() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  static Future<String?> getDeviceToken() {
    return _messaging.getToken();
  }

  static Future<void> showWelcomeNotification({String? name}) {
    final userName = name?.trim();
    return showLocalNotification(
      title: 'Bienvenido',
      body: userName == null || userName.isEmpty
          ? 'Ya puedes explorar las ventas de garage.'
          : '$userName, ya puedes explorar las ventas de garage.',
    );
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) {
    return _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'garage_sale_alerts',
          'Garage Sale',
          channelDescription: 'Alertas importantes de Garage Sale App',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
    );
  }

  static Future<void> _createAndroidChannel() async {
    if (kIsWeb) return;

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  static Future<void> _showForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await showLocalNotification(
      title: notification.title ?? 'Garage Sale',
      body: notification.body ?? 'Tienes una nueva notificacion.',
    );
  }
}
