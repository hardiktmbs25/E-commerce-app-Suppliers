// lib/modules/settings/settings_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/local_storage_service.dart';

class SettingsController extends GetxController {
  final RxBool isDarkMode               = false.obs;
  final RxBool deliveryReminders        = true.obs;
  final RxBool paymentReminders         = true.obs;
  final RxBool dailySummaryNotification = true.obs;
  final RxString reminderTime           = '06:00 AM'.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = LocalStorageService.isDarkMode;
    deliveryReminders.value =
    LocalStorageService.getSetting<bool>('delivery_reminders',
        defaultValue: true)!;
    paymentReminders.value =
    LocalStorageService.getSetting<bool>('payment_reminders',
        defaultValue: true)!;
    dailySummaryNotification.value =
    LocalStorageService.getSetting<bool>('daily_summary',
        defaultValue: true)!;
    reminderTime.value =
    LocalStorageService.getSetting<String>('reminder_time',
        defaultValue: '06:00 AM')!;
  }

  Future<void> toggleDarkMode(bool val) async {
    isDarkMode.value = val;
    await LocalStorageService.setDarkMode(val);
    Get.changeThemeMode(val ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggleDeliveryReminders(bool val) async {
    deliveryReminders.value = val;
    await LocalStorageService.saveSetting('delivery_reminders', val);
  }

  Future<void> togglePaymentReminders(bool val) async {
    paymentReminders.value = val;
    await LocalStorageService.saveSetting('payment_reminders', val);
  }

  Future<void> toggleDailySummary(bool val) async {
    dailySummaryNotification.value = val;
    await LocalStorageService.saveSetting('daily_summary', val);
  }

  Future<void> setReminderTime(String time) async {
    reminderTime.value = time;
    await LocalStorageService.saveSetting('reminder_time', time);
  }

  Future<void> clearCache() async {
    await LocalStorageService.clearDeliveries();
    await LocalStorageService.clearCustomers();
    await LocalStorageService.clearSubscriptions();
    Get.snackbar('✅ Cache Cleared',
        'Local cache cleared. Data will re-sync from server.',
        snackPosition: SnackPosition.TOP);
  }
}
