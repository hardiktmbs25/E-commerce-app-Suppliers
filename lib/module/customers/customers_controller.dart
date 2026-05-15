// lib/modules/customers/customers_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';
import '../../services/local_storage_service.dart';
import '../../core/utils/logger.dart';

class CustomersController extends GetxController {
  final CustomerRepository _repo = Get.find<CustomerRepository>();

  final RxList<CustomerModel> allCustomers      = <CustomerModel>[].obs;
  final RxList<CustomerModel> filteredCustomers = <CustomerModel>[].obs;
  final RxString searchQuery     = ''.obs;
  final RxString statusFilter    = 'all'.obs; // all, active, inactive, paused
  final RxBool   isLoading       = true.obs;

  final String? vendorId = LocalStorageService.getVendor()?.id;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    // Pre-fill from cache
    allCustomers.assignAll(LocalStorageService.getCustomers());
    filteredCustomers.assignAll(allCustomers);

    // Debounce search
    debounce(searchQuery, (_) => _applyFilter(),
        time: const Duration(milliseconds: 350));
    ever(statusFilter, (_) => _applyFilter());
  }

  @override
  void onReady() {
    super.onReady();
    _initStream();
  }

  void _initStream() {
    if (vendorId == null) return;
    _sub = _repo.watchCustomers(vendorId!).listen(
          (list) {
        allCustomers.assignAll(list);
        _applyFilter();
        isLoading.value = false;
      },
      onError: (e) {
        AppLogger.e('Customers stream error', e);
        isLoading.value = false;
      },
    );
  }

  void _applyFilter() {
    var result = allCustomers.toList();
    if (statusFilter.value != 'all') {
      result = result.where((c) => c.statusStr == statusFilter.value).toList();
    }
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((c) =>
      c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          c.address.toLowerCase().contains(q)).toList();
    }
    filteredCustomers.assignAll(result);
  }

  void setSearch(String q) => searchQuery.value = q;
  void setFilter(String f) => statusFilter.value = f;

  Future<void> deleteCustomer(CustomerModel customer) async {
    if (vendorId == null) return;
    await _repo.deleteCustomer(vendorId!, customer.id);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}