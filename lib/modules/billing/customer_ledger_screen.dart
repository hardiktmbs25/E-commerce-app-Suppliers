// lib/modules/billing/customer_ledger_screen.dart
//
// Full running-balance ledger for one customer.
// Accepts route argument: Map { 'customerId': String, 'customerName': String }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/ledger_entry_model.dart';
import '../../data/repositories/billing_repository.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_box.dart';

class CustomerLedgerScreen extends StatefulWidget {
  const CustomerLedgerScreen({super.key});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  final BillingRepository _repo = Get.find<BillingRepository>();

  late final String customerId;
  late final String customerName;
  late final String vendorId;

  // Show local cache immediately, then live stream overlays when online
  List<LedgerEntryModel> localEntries = [];
  StreamSubscription?    _sub;
  bool                   isLoading = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    customerId   = args['customerId'] as String? ?? '';
    customerName = args['customerName'] as String? ?? 'Customer';
    vendorId     = LocalStorageService.getVendor()?.id ?? '';

    // Show local immediately
    localEntries = LocalStorageService.getLedgerForCustomer(customerId);
    isLoading    = false;

    // Subscribe to Firestore stream for live updates
    _sub = _repo.watchCustomerLedger(vendorId, customerId).listen(
          (entries) {
        if (mounted) setState(() { localEntries = entries; });
      },
      onError: (_) {}, // fall back to local cache silently
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balance = localEntries.isEmpty
        ? 0.0 : localEntries.last.balanceAfter;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(customerName,
            style: const TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w700)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: balance > 0 ? AppColors.error : AppColors.success,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              const Text('Running Balance',
                  style: TextStyle(fontSize: 12, color: Colors.white70,
                      fontFamily: 'Poppins')),
              const Spacer(),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 22,
                    fontWeight: FontWeight.w900, color: Colors.white,
                    fontFamily: 'Poppins'),
              ),
            ]),
          ),
        ),
      ),
      body: isLoading
          ? ListView(padding: const EdgeInsets.all(16), children: [
        const ShimmerBox(height: 60),
        const SizedBox(height: 8),
        const ShimmerBox(height: 60),
        const SizedBox(height: 8),
        const ShimmerBox(height: 60),
      ])
          : localEntries.isEmpty
          ? const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Entries Yet',
        subtitle: 'Entries will appear as deliveries are\nmarked delivered and payments are collected.',
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: localEntries.length,
        separatorBuilder: (_, __) => const Divider(
            height: 1, color: AppColors.divider),
        itemBuilder: (_, i) =>
            _LedgerRow(entry: localEntries[i]),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final LedgerEntryModel entry;
  const _LedgerRow({required this.entry});

  Color get _amtColor => entry.isCredit ? AppColors.success : AppColors.textPrimary;
  String get _amtLabel {
    final sign  = entry.isCredit ? '−' : '+';
    return '$sign₹${entry.amount.abs().toStringAsFixed(2)}';
  }

  IconData get _icon {
    switch (entry.entryType) {
      case LedgerEntryType.payment:  return Icons.payments_rounded;
      case LedgerEntryType.discount: return Icons.discount_outlined;
      case LedgerEntryType.carryFwd: return Icons.redo_rounded;
      case LedgerEntryType.extra:    return Icons.add_shopping_cart_rounded;
      default:                       return Icons.local_shipping_outlined;
    }
  }

  Color get _iconBg {
    switch (entry.entryType) {
      case LedgerEntryType.payment:  return AppColors.success;
      case LedgerEntryType.discount: return AppColors.info;
      case LedgerEntryType.carryFwd: return AppColors.warning;
      case LedgerEntryType.extra:    return AppColors.accent;
      default:                       return AppColors.primary;
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month]}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: _iconBg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(_icon, size: 18, color: _iconBg),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.description,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary, fontFamily: 'Poppins'),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(_formatDate(entry.createdAt),
              style: const TextStyle(fontSize: 10,
                  color: AppColors.textHint, fontFamily: 'Poppins')),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_amtLabel,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: _amtColor, fontFamily: 'Poppins')),
          Text('Bal ₹${entry.balanceAfter.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 10,
                  color: AppColors.textSecondary, fontFamily: 'Poppins')
          ),
        ]),
      ]),
    );
  }
}
