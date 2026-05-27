// lib/module/billing/payment_history_screen.dart
//
// Full payment history for a vendor — filterable by customer and date.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/billing_repository.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_box.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final BillingRepository _repo = Get.find<BillingRepository>();

  List<PaymentModel> _all      = [];
  List<PaymentModel> _filtered = [];
  bool               _loading  = true;
  String             _searchQ  = '';
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    final vendorId = LocalStorageService.getVendor()?.id ?? '';
    // Load local cache immediately
    _all      = LocalStorageService.getPayments()
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    _filtered = List.from(_all);
    _loading  = false;

    // Live updates from Firestore (today's stream)
    _sub = _repo.watchTodayPayments(vendorId).listen(
          (payments) {
        if (mounted) setState(() { _applySearch(_searchQ); });
      },
      onError: (_) {},
    );
  }

  void _applySearch(String q) {
    _searchQ  = q.toLowerCase();
    _filtered = _searchQ.isEmpty
        ? List.from(_all)
        : _all.where((p) =>
        p.customerName.toLowerCase().contains(_searchQ)).toList();
    if (mounted) setState(() {});
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  double get _totalToday {
    final today = DateTime.now();
    return _filtered.where((p) {
      final d = p.paidAt;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).fold(0.0, (s, p) => s + p.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment History',
            style: TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        // Today total banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.payments_outlined,
                color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            const Text("Today's Total",
                style: TextStyle(fontSize: 13,
                    color: AppColors.success, fontFamily: 'Poppins')),
            const Spacer(),
            Text('₹${_totalToday.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, color: AppColors.success,
                    fontFamily: 'Poppins')),
          ]),
        ),
        const SizedBox(height: 10),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search customer...',
              prefixIcon: const Icon(Icons.search, size: 18,
                  color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              hintStyle: const TextStyle(
                  fontFamily: 'Poppins', color: AppColors.textHint,
                  fontSize: 13),
            ),
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
            onChanged: _applySearch,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _loading
            ? ListView(padding: const EdgeInsets.all(16), children: [
          const ShimmerBox(height: 60), const SizedBox(height: 8),
          const ShimmerBox(height: 60), const SizedBox(height: 8),
          const ShimmerBox(height: 60),
        ])
            : _filtered.isEmpty
            ? const EmptyState(
          icon: Icons.receipt_outlined,
          title: 'No Payments',
          subtitle: 'Payments will appear here.',
        )
            : ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: _filtered.length,
          separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (_, i) =>
              _PaymentTile(payment: _filtered[i]),
        )),
      ]),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentTile({required this.payment});

  String _fmt(DateTime dt) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month]} ${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.payments_rounded,
              size: 20, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(payment.customerName,
              style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
          Text('${payment.methodLabel}  •  ${_fmt(payment.paidAt)}',
              style: const TextStyle(fontSize: 11,
                  color: AppColors.textHint, fontFamily: 'Poppins')),
          if (payment.note != null && payment.note!.isNotEmpty)
            Text(payment.note!,
                style: const TextStyle(fontSize: 10,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                    fontStyle: FontStyle.italic)),
        ])),
        Text('₹${payment.amount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 16,
                fontWeight: FontWeight.w800, color: AppColors.success,
                fontFamily: 'Poppins')),
      ]),
    );
  }
}