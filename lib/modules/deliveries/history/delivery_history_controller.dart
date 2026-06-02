// lib/modules/deliveries/history/delivery_history_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/models/delivery_model.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../../services/local_storage_service.dart';

class DeliveryHistoryController extends GetxController {
  final DeliveryRepository _repo = Get.find<DeliveryRepository>();

  final searchCtrl = TextEditingController();
  final RxList<DeliveryModel> deliveries     = <DeliveryModel>[].obs;
  final RxBool  isLoading      = true.obs;
  final RxBool  isFetchingMore = false.obs;
  final RxBool  hasMore        = true.obs;
  final RxString searchQuery   = ''.obs;

  // Filters
  final Rx<DateTime?> startDate  = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate    = Rx<DateTime?>(null);
  final RxString statusFilter    = ''.obs;

  DocumentSnapshot? _lastDoc;

  String? get vendorId => LocalStorageService.getVendor()?.id;

  bool get hasFilters =>
      startDate.value != null || endDate.value != null || statusFilter.value.isNotEmpty;

  String get activeFilterLabel {
    final parts = <String>[];
    if (statusFilter.value.isNotEmpty) parts.add(statusFilter.value.toCapitalCase);
    if (startDate.value != null) parts.add('From ${startDate.value!.dayMonth}');
    if (endDate.value != null) parts.add('To ${endDate.value!.dayMonth}');
    return parts.join(' · ');
  }

  @override
  void onReady() {
    super.onReady();
    fetchHistory();
  }

  Future<void> fetchHistory({bool reset = true}) async {
    if (vendorId == null) return;

    if (reset) {
      isLoading.value = true;
      _lastDoc = null;
      deliveries.clear();
      hasMore.value = true;
    }

    final result = await _repo.fetchDeliveryHistory(
      vendorId!,
      startDate:  startDate.value,
      endDate:    endDate.value,
      status:     statusFilter.value.isEmpty ? null : statusFilter.value,
      lastDoc:    _lastDoc,
    );

    result.fold(
          (f) {
        Get.snackbar('Error', f.message, snackPosition: SnackPosition.TOP);
        isLoading.value = false;
        isFetchingMore.value = false;
      },
          (list) {
        if (list.isEmpty) {
          hasMore.value = false;
        } else {
          deliveries.addAll(_applySearch(list));
          // We can't easily track lastDoc without access to the raw snapshot here,
          // so we track by count: if fewer than pageSize returned, no more pages.
          if (list.length < 20) hasMore.value = false;
        }
        isLoading.value = false;
        isFetchingMore.value = false;
      },
    );
  }

  List<DeliveryModel> _applySearch(List<DeliveryModel> list) {
    if (searchQuery.value.isEmpty) return list;
    final q = searchQuery.value.toLowerCase();
    return list.where((d) =>
    d.customerName.toLowerCase().contains(q) ||
        d.customerAddress.toLowerCase().contains(q)).toList();
  }

  void loadMore() {
    if (!hasMore.value || isFetchingMore.value) return;
    isFetchingMore.value = true;
    fetchHistory(reset: false);
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    fetchHistory();
  }

  void clearSearch() {
    searchCtrl.clear();
    searchQuery.value = '';
    fetchHistory();
  }

  void clearFilters() {
    startDate.value  = null;
    endDate.value    = null;
    statusFilter.value = '';
    fetchHistory();
  }

  void showFilterSheet() {
    final tempStatus = statusFilter.value.obs;
    final tempStart  = startDate.value.obs;
    final tempEnd    = endDate.value.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Filter Deliveries',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
            IconButton(onPressed: Get.back, icon: const Icon(Icons.close_rounded)),
          ]),

          const SizedBox(height: 12),
          const Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.textSecondary, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          Obx(() => Wrap(
            spacing: 8,
            children: ['', 'pending', 'delivered', 'missed', 'cancelled'].map((s) {
              final isSelected = tempStatus.value == s;
              return GestureDetector(
                onTap: () => tempStatus.value = s,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(s.isEmpty ? 'All' : s.toCapitalCase,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontFamily: 'Poppins')),
                ),
              );
            }).toList(),
          )),

          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _DatePickerTile(
              label: 'Start Date',
              date: tempStart,
            )),
            const SizedBox(width: 12),
            Expanded(child: _DatePickerTile(
              label: 'End Date',
              date: tempEnd,
            )),
          ]),

          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () {
                Get.back();
                clearFilters();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Clear', style: TextStyle(fontFamily: 'Poppins')),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () {
                statusFilter.value = tempStatus.value;
                startDate.value    = tempStart.value;
                endDate.value      = tempEnd.value;
                Get.back();
                fetchHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white,
                  fontFamily: 'Poppins')),
            )),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
      isScrollControlled: true,
    );
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}

class _DatePickerTile extends StatelessWidget {
  final String label;
  final Rx<DateTime?> date;
  const _DatePickerTile({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date.value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) date.value = picked;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: date.value != null
              ? AppColors.primary : AppColors.border),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 14,
              color: date.value != null ? AppColors.primary : AppColors.textHint),
          const SizedBox(width: 6),
          Expanded(child: Text(
            date.value != null ? date.value!.dayMonth : label,
            style: TextStyle(fontSize: 12, fontFamily: 'Poppins',
                color: date.value != null ? AppColors.textPrimary : AppColors.textHint),
          )),
          if (date.value != null)
            GestureDetector(
              onTap: () => date.value = null,
              child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textHint),
            ),
        ]),
      ),
    ));
  }
}
