// lib/services/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../core/utils/logger.dart';

class NotificationService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  final RxInt unreadCount = 0.obs;

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'vendortrack_channel',
    'VendorTrack Notifications',
    description: 'Delivery and payment alerts',
    importance: Importance.high,
  );

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// Main initialization
  Future<void> _initialize() async {
    try {
      await _initLocalNotifications();
      await _requestPermission();
      await _setupFCMHandlers();

      AppLogger.i('NotificationService initialized');
    } catch (e) {
      AppLogger.e('NotificationService initialization failed', e);
    }
  }

  /// Initialize local notifications
  Future<void> _initLocalNotifications() async {
    const androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    /// Create Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    AppLogger.i('Local notifications initialized');
  }

  /// Request FCM permissions
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    AppLogger.i(
      'FCM permission status: ${settings.authorizationStatus}',
    );
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();

      AppLogger.i('FCM Token: $token');

      return token;
    } catch (e) {
      AppLogger.e('Failed to get FCM token', e);
      return null;
    }
  }

  /// Setup Firebase Messaging listeners
  Future<void> _setupFCMHandlers() async {
    /// Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.d(
        'Foreground notification: ${message.notification?.title}',
      );

      _showLocalNotification(message);

      unreadCount.value++;
    });

    /// Notification tap when app in background
    FirebaseMessaging.onMessageOpenedApp
        .listen((RemoteMessage message) {
      AppLogger.d('Notification opened from background');

      _handleNotificationNavigation(message.data);
    });

    /// Notification tap when app terminated
    final initialMessage =
    await _messaging.getInitialMessage();

    if (initialMessage != null) {
      AppLogger.d('Notification opened from terminated app');

      _handleNotificationNavigation(initialMessage.data);
    }

    AppLogger.i('FCM handlers configured');
  }

  /// Show local notification
  Future<void> _showLocalNotification(
      RemoteMessage message,
      ) async {
    final notification = message.notification;

    if (notification == null) return;

    await _localNotifications.show(
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
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data.toString(),
    );
  }

  /// Notification tap callback
  void _onNotificationTap(
      NotificationResponse response,
      ) {
    AppLogger.d(
      'Notification tapped: ${response.payload}',
    );
  }

  /// Navigate based on notification data
  void _handleNotificationNavigation(
      Map<String, dynamic> data,
      ) {
    final type = data['type'];

    switch (type) {
      case 'delivery':
        Get.toNamed('/deliveries');
        break;

      case 'payment':
        Get.toNamed('/payments');
        break;

      default:
        Get.toNamed('/dashboard');
        break;
    }
  }

  /// Example scheduled notification
  Future<void> scheduleDeliveryReminder() async {
    AppLogger.i('Delivery reminder scheduled');
  }

  /// Clear unread notification counter
  void clearUnreadCount() {
    unreadCount.value = 0;
  }
}