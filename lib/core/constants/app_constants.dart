// lib/core/constants/app_constants.dart
abstract class AppConstants {
  // ── Collections ───────────────────────────────────────────────────────
  static const colVendors       = 'vendors';
  static const colCustomers     = 'customers';
  static const colSubscriptions = 'subscriptions';
  static const colDeliveries    = 'deliveries';
  static const colInvoices      = 'invoices';
  static const colPayments      = 'payments';
  static const colNotifications = 'notifications';
  static const colRoutes        = 'routes';
  static const colPlans         = 'plans';
  static const colAreas         = 'areas';
  static const colTimeSlots     = 'timeSlots';
  static const colBillEntries     = 'billEntries';

  // ── Hive boxes ────────────────────────────────────────────────────────
  static const boxSettings      = 'settings';
  static const boxVendor        = 'vendor';
  static const boxCustomers     = 'customers_cache';
  static const boxDeliveries    = 'deliveries_cache';
  static const boxSyncQueue     = 'sync_queue';
  static const boxSubscriptions = 'subscriptions_cache';

  // ── Hive type IDs ─────────────────────────────────────────────────────
  static const tidVendorModel       = 0;
  static const tidCustomerModel     = 1;
  static const tidSubscriptionModel = 2;
  static const tidDeliveryModel     = 3;
  static const tidSyncAction        = 4;

  // ── Dimensions ────────────────────────────────────────────────────────
  static const paddingXS   = 4.0;
  static const paddingS    = 8.0;
  static const paddingM    = 16.0;
  static const paddingL    = 20.0;
  static const paddingXL   = 24.0;
  static const paddingXXL  = 32.0;

  static const radiusS     = 8.0;
  static const radiusM     = 12.0;
  static const radiusL     = 16.0;
  static const radiusXL    = 20.0;
  static const radiusXXL   = 28.0;
  static const radiusFull  = 100.0;

  // ── Durations ─────────────────────────────────────────────────────────
  static const animFast    = Duration(milliseconds: 150);
  static const animNormal  = Duration(milliseconds: 280);
  static const animSlow    = Duration(milliseconds: 450);

  // ── Pagination ────────────────────────────────────────────────────────
  static const pageSize    = 20;

  // ── Sync ──────────────────────────────────────────────────────────────
  static const syncRetryDelay   = Duration(seconds: 30);
  static const maxSyncRetries   = 5;
  static const offlineBatchSize = 50;

  // ── Business ──────────────────────────────────────────────────────────
  static const maxRouteCustomers = 100;
  static const billDueDays       = 5; // days after month end
}