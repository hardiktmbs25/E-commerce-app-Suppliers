// lib/services/local_storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../data/models/customer_model.dart';
import '../data/models/delivery_model.dart';
import '../data/models/subscription_model.dart';
import '../data/models/sync_action_model.dart';
import '../data/models/vendor_model.dart';

/// Single gateway for all local Hive storage.
///
/// WHY THIS EXISTS:
/// All offline reads/writes go through this services. Controllers and repositories
/// never call Hive directly. This makes it trivial to swap Hive for another
/// local store (e.g., Isar or SQLite) without touching business logic.
///
/// OFFLINE STRATEGY:
/// 1. Reads: Always return local cache first (instant, zero-latency).
/// 2. Writes: Write locally first, then enqueue a SyncAction.
/// 3. Sync: SyncService drains the queue when online.
class LocalStorageService {
  static late Box<dynamic>     _settings;
  static late Box<VendorModel>       _vendorBox;
  static late Box<CustomerModel>     _customersBox;
  static late Box<DeliveryModel>     _deliveriesBox;
  static late Box<SubscriptionModel> _subscriptionsBox;
  static late Box<SyncActionModel>   _syncQueueBox;

  static Future<void> init() async {
    _settings         = await Hive.openBox(AppConstants.boxSettings);
    _vendorBox        = await Hive.openBox<VendorModel>(AppConstants.boxVendor);
    _customersBox     = await Hive.openBox<CustomerModel>(AppConstants.boxCustomers);
    _deliveriesBox    = await Hive.openBox<DeliveryModel>(AppConstants.boxDeliveries);
    _subscriptionsBox = await Hive.openBox<SubscriptionModel>(AppConstants.boxSubscriptions);
    _syncQueueBox     = await Hive.openBox<SyncActionModel>(AppConstants.boxSyncQueue);
    AppLogger.i('LocalStorageService initialized');
  }

  // ── Settings ─────────────────────────────────────────────────────────
  static T? getSetting<T>(String key, {T? defaultValue}) =>
      _settings.get(key, defaultValue: defaultValue);

  static Future<void> saveSetting(String key, dynamic value) =>
      _settings.put(key, value);

  static Future<void> deleteSetting(String key) => _settings.delete(key);

  static bool get isDarkMode => getSetting('dark_mode', defaultValue: false)!;
  static Future<void> setDarkMode(bool value) => saveSetting('dark_mode', value);

  static String? get vendorId => getSetting('vendor_id');
  static Future<void> setVendorId(String id) => saveSetting('vendor_id', id);

  static bool get isLoggedIn => vendorId != null;

  // ── Vendor ────────────────────────────────────────────────────────────
  static VendorModel? getVendor() => _vendorBox.get('current');
  static Future<void> saveVendor(VendorModel vendor) =>
      _vendorBox.put('current', vendor);
  static Future<void> clearVendor() => _vendorBox.clear();

  // ── Customers ─────────────────────────────────────────────────────────
  static List<CustomerModel> getCustomers() => _customersBox.values.toList();
  static CustomerModel? getCustomer(String id) => _customersBox.get(id);

  static Future<void> saveCustomer(CustomerModel customer) =>
      _customersBox.put(customer.id, customer);

  static Future<void> saveCustomers(List<CustomerModel> customers) async {
    final map = {for (final c in customers) c.id: c};
    await _customersBox.putAll(map);
  }

  static Future<void> deleteCustomer(String id) => _customersBox.delete(id);
  static Future<void> clearCustomers() => _customersBox.clear();

  // ── Deliveries ────────────────────────────────────────────────────────
  static List<DeliveryModel> getDeliveries() => _deliveriesBox.values.toList();

  static List<DeliveryModel> getTodayDeliveries() {
    final today = DateTime.now();
    return _deliveriesBox.values.where((d) {
      final s = d.scheduledDate;
      return s.year == today.year && s.month == today.month && s.day == today.day;
    }).toList()
      ..sort((a, b) => a.routeOrder.compareTo(b.routeOrder));
  }

  static Future<void> saveDelivery(DeliveryModel delivery) =>
      _deliveriesBox.put(delivery.id, delivery);

  static Future<void> saveDeliveries(List<DeliveryModel> deliveries) async {
    final map = {for (final d in deliveries) d.id: d};
    await _deliveriesBox.putAll(map);
  }

  static Future<void> clearDeliveries() => _deliveriesBox.clear();

  // ── Subscriptions ─────────────────────────────────────────────────────
  static List<SubscriptionModel> getSubscriptions() =>
      _subscriptionsBox.values.toList();

  static Future<void> saveSubscription(SubscriptionModel sub) =>
      _subscriptionsBox.put(sub.id, sub);

  static Future<void> saveSubscriptions(List<SubscriptionModel> subs) async {
    final map = {for (final s in subs) s.id: s};
    await _subscriptionsBox.putAll(map);
  }

  static Future<void> clearSubscriptions() => _subscriptionsBox.clear();

  // ── Sync Queue ────────────────────────────────────────────────────────
  static List<SyncActionModel> getSyncQueue() =>
      _syncQueueBox.values.where((a) => !a.isFailed).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  static Future<void> enqueueSyncAction(SyncActionModel action) =>
      _syncQueueBox.put(action.id, action);

  static Future<void> removeSyncAction(String id) => _syncQueueBox.delete(id);

  static Future<void> markSyncActionFailed(String id) async {
    final action = _syncQueueBox.get(id);
    if (action != null) {
      action.isFailed = true;
      await action.save();
    }
  }

  static int get pendingSyncCount =>
      _syncQueueBox.values.where((a) => !a.isFailed).length;

  // ── Clear all (logout) ────────────────────────────────────────────────
  static Future<void> clearAll() async {
    await _settings.clear();
    await _vendorBox.clear();
    await _customersBox.clear();
    await _deliveriesBox.clear();
    await _subscriptionsBox.clear();
    await _syncQueueBox.clear();
    AppLogger.i('LocalStorageService cleared (logout)');
  }
}