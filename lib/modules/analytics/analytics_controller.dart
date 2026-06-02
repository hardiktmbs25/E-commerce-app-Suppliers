// lib/modules/analytics/analytics_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/models/delivery_model.dart';
import '../../services/local_storage_service.dart';

class MonthlyRevenueStat {
  final String month;
  final double revenue;
  const MonthlyRevenueStat(this.month, this.revenue);
}

class AnalyticsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<MonthlyRevenueStat> revenueStats = <MonthlyRevenueStat>[].obs;
  final RxDouble thisMonthRevenue  = 0.0.obs;
  final RxDouble lastMonthRevenue  = 0.0.obs;
  final RxInt    totalDeliveries   = 0.obs;
  final RxInt    deliveredCount    = 0.obs;
  final RxInt    missedCount       = 0.obs;
  final RxDouble deliveryRate      = 0.0.obs;
  final RxBool   isLoading         = true.obs;

  String? get vendorId => LocalStorageService.getVendor()?.id;

  @override
  void onReady() {
    super.onReady();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (vendorId == null) return;
    isLoading.value = true;

    try {
      final now = DateTime.now();
      // Last 6 months revenue from invoices
      final stats = <MonthlyRevenueStat>[];
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        final snap = await _db
            .collection('${AppConstants.colVendors}/$vendorId/${AppConstants.colInvoices}')
            .where('month', isEqualTo: d.month)
            .where('year', isEqualTo: d.year)
            .get();
        final total = snap.docs.fold<double>(
            0, (s, doc) => s + ((doc.data()['totalAmount'] ?? 0) as num).toDouble());
        stats.add(MonthlyRevenueStat(_monthLabel(d.month), total));
      }
      revenueStats.assignAll(stats);

      if (stats.length >= 2) {
        thisMonthRevenue.value = stats.last.revenue;
        lastMonthRevenue.value = stats[stats.length - 2].revenue;
      }

      // Delivery success rate (last 30 days)
      final start = now.subtract(const Duration(days: 30));
      final delivSnap = await _db
          .collection('${AppConstants.colVendors}/$vendorId/${AppConstants.colDeliveries}')
          .where('scheduledDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();

      totalDeliveries.value = delivSnap.docs.length;
      deliveredCount.value = delivSnap.docs
          .where((d) => d.data()['status'] == DeliveryStatus.delivered.name)
          .length;
      missedCount.value = delivSnap.docs
          .where((d) => d.data()['status'] == DeliveryStatus.missed.name)
          .length;
      deliveryRate.value = totalDeliveries.value > 0
          ? deliveredCount.value / totalDeliveries.value
          : 0;

      isLoading.value = false;
    } catch (e) {
      AppLogger.e('AnalyticsController error', e);
      isLoading.value = false;
    }
  }

  String _monthLabel(int month) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[month];
  }

  double get revenueGrowth {
    if (lastMonthRevenue.value == 0) return 0;
    return ((thisMonthRevenue.value - lastMonthRevenue.value) /
        lastMonthRevenue.value) * 100;
  }

  double get maxRevenue =>
      revenueStats.isEmpty ? 1 :
      revenueStats.map((s) => s.revenue).reduce((a, b) => a > b ? a : b);
}
