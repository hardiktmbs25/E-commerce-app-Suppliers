// lib/modules/payments/payments_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../services/local_storage_service.dart';

class PaymentRecord {
  final String id;
  final String customerId;
  final String customerName;
  final String invoiceId;
  final double amount;
  final String paymentMethod;
  final String? notes;
  final DateTime paidAt;

  const PaymentRecord({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    this.notes,
    required this.paidAt,
  });

  factory PaymentRecord.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PaymentRecord(
      id:            doc.id,
      customerId:    d['customerId'] ?? '',
      customerName:  d['customerName'] ?? '',
      invoiceId:     d['invoiceId'] ?? '',
      amount:        (d['amount'] ?? 0).toDouble(),
      paymentMethod: d['paymentMethod'] ?? 'cash',
      notes:         d['notes'],
      paidAt:        (d['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get methodEmoji {
    switch (paymentMethod) {
      case 'upi':    return '📱';
      case 'online': return '💳';
      default:       return '💵';
    }
  }
}

class PaymentsController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<PaymentRecord> payments    = <PaymentRecord>[].obs;
  final RxBool  isLoading                 = true.obs;
  final RxDouble totalCollectedToday      = 0.0.obs;
  final RxDouble totalCollectedThisMonth  = 0.0.obs;
  final RxString filterMethod             = 'all'.obs;

  String? get vendorId => LocalStorageService.getVendor()?.id;
  StreamSubscription? _sub;

  final methods = ['all', 'cash', 'upi', 'online'];

  @override
  void onReady() {
    super.onReady();
    _initStream();
  }

  void _initStream() {
    if (vendorId == null) return;

    final thirtyDaysAgo =
    DateTime.now().subtract(const Duration(days: 30));

    _sub = _db
        .collection('${AppConstants.colVendors}/$vendorId/${AppConstants.colPayments}')
        .where('paidAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .orderBy('paidAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
        final list =
        snap.docs.map((d) => PaymentRecord.fromFirestore(d)).toList();
        payments.assignAll(list);
        _computeTotals(list);
        isLoading.value = false;
      },
      onError: (e) {
        AppLogger.e('Payments stream error', e);
        isLoading.value = false;
      },
    );
  }

  void _computeTotals(List<PaymentRecord> list) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    totalCollectedToday.value = list
        .where((p) => p.paidAt.isAfter(today))
        .fold(0.0, (total, p) => total + p.amount);

    totalCollectedThisMonth.value =
        list.fold(0.0, (total, p) => total + p.amount);
  }

  List<PaymentRecord> get filteredPayments {
    if (filterMethod.value == 'all') return payments;
    return payments
        .where((p) => p.paymentMethod == filterMethod.value)
        .toList();
  }

  Map<String, double> get methodBreakdown {
    final result = <String, double>{};
    for (final p in payments) {
      result[p.paymentMethod] = (result[p.paymentMethod] ?? 0) + p.amount;
    }
    return result;
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
