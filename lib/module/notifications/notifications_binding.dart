// lib/module/notifications/notifications_binding.dart
import 'package:get/get.dart';
import 'notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationsController>(() => NotificationsController());
  }
}