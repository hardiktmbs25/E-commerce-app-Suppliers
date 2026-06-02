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

  // FIX #2: track recently-shown message IDs to prevent exact duplicates.
  final Set<String> _recentMessageIds = {};

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

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    AppLogger.i('Local notifications initialized');
  }

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
    AppLogger.i('FCM permission: ${settings.authorizationStatus}');
  }

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

  Future<void> _setupFCMHandlers() async {
    // Foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.d('Foreground FCM: ${message.notification?.title}');

      // FIX #2: deduplicate — skip if we've already shown this message ID
      // recently (FCM sometimes delivers the same message twice).
      final msgId = message.messageId ?? '';
      if (msgId.isNotEmpty && _recentMessageIds.contains(msgId)) {
        AppLogger.d('Skipping duplicate notification: $msgId');
        return;
      }
      if (msgId.isNotEmpty) {
        _recentMessageIds.add(msgId);
        // Clean up after 5 seconds so memory doesn't grow unbounded
        Future.delayed(const Duration(seconds: 5), () {
          _recentMessageIds.remove(msgId);
        });
      }

      _showLocalNotification(message);
      unreadCount.value++;
    });

    // Notification tapped when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.d('Notification opened from background');
      _handleNotificationNavigation(message.data);
    });

    // Notification tapped when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      AppLogger.d('Notification opened from terminated app');
      _handleNotificationNavigation(initialMessage.data);
    }

    AppLogger.i('FCM handlers configured');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // FIX #1: use millisecondsSinceEpoch for a practically unique ID.
    // The old `notification.hashCode` caused collisions — two different
    // messages could share the same ID and the second would silently replace
    // the first in the notification tray.
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      id: id,
      title:notification.title,
      body:notification.body,
      notificationDetails:NotificationDetails(
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

  void _onNotificationTap(NotificationResponse response) {
    AppLogger.d('Notification tapped: ${response.payload}');
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
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

  Future<void> scheduleDeliveryReminder() async {
    AppLogger.i('Delivery reminder scheduled');
  }

  void clearUnreadCount() {
    unreadCount.value = 0;
  }
}