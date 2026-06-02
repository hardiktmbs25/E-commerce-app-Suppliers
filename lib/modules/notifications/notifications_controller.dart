// lib/modules/notifications/notifications_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../services/local_storage_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'delivery', 'payment', 'subscription', 'system'
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id:        doc.id,
      title:     d['title'] ?? '',
      body:      d['body'] ?? '',
      type:      d['type'] ?? 'system',
      isRead:    d['isRead'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  IconData get icon {
    switch (type) {
      case 'delivery':     return Icons.local_shipping_rounded;
      case 'payment':      return Icons.payments_rounded;
      case 'subscription': return Icons.subscriptions_rounded;
      default:             return Icons.notifications_rounded;
    }
  }

  int get iconColor {
    switch (type) {
      case 'delivery':     return 0xFF3B82F6;
      case 'payment':      return 0xFF22C55E;
      case 'subscription': return 0xFF8B5CF6;
      default:             return 0xFF6B7280;
    }
  }
}

class NotificationsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading  = true.obs;

  String? get vendorId => LocalStorageService.getVendor()?.id;
  StreamSubscription? _sub;

  @override
  void onReady() {
    super.onReady();
    _initStream();
  }

  void _initStream() {
    if (vendorId == null) return;
    _sub = _db
        .collection(AppConstants.colVendors)
        .doc(vendorId)
        .collection(AppConstants.colNotifications)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snap) {
        final list = snap.docs
            .map((d) => AppNotification.fromFirestore(d))
            .toList();
        notifications.assignAll(list);
        unreadCount.value = list.where((n) => !n.isRead).length;
        isLoading.value = false;
      },
      onError: (e) {
        AppLogger.e('Notifications stream error', e);
        isLoading.value = false;
      },
    );
  }

  Future<void> markAllRead() async {
    if (vendorId == null) return;
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    final batch = _db.batch();
    for (final n in unread) {
      batch.update(
        _db
            .collection(AppConstants.colVendors)
            .doc(vendorId)
            .collection(AppConstants.colNotifications)
            .doc(n.id),
        {'isRead': true},
      );
    }
    await batch.commit();
  }

  Future<void> markRead(String notificationId) async {
    if (vendorId == null) return;
    await _db
        .collection(AppConstants.colVendors)
        .doc(vendorId)
        .collection(AppConstants.colNotifications)
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    if (vendorId == null) return;
    await _db
        .collection(AppConstants.colVendors)
        .doc(vendorId)
        .collection(AppConstants.colNotifications)
        .doc(notificationId)
        .delete();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
