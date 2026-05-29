// lib/modules/deliveries/add/add_delivery_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/customer_model.dart';
import '../../../data/models/subscription_model.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/delivery_repository.dart';
import '../../../services/local_storage_service.dart';

/// Delivery type chosen by user
enum AddDeliveryType { manual, fromSubscription }

class AddDeliveryController extends GetxController {
  final DeliveryRepository _repo = Get.find<DeliveryRepository>();

  // ── Tab / mode ─────────────────────────────────────────────────────────
  final Rx<AddDeliveryType> deliveryType = AddDeliveryType.manual.obs;

  // ── Shared state ───────────────────────────────────────────────────────
  final Rx<CustomerModel?>      selectedCustomer     = Rx<CustomerModel?>(null);
  final RxList<CustomerModel>   customerSuggestions  = <CustomerModel>[].obs;
  final RxList<SubscriptionModel> customerSubs       = <SubscriptionModel>[].obs;
  final Rx<SubscriptionModel?>  selectedSubscription = Rx<SubscriptionModel?>(null);
  final Rx<DateTime>            scheduledDate        = DateTime.now().obs;
  final RxBool                  isSubmitting         = false.obs;
  final RxBool                  saveAsCustomer       = false.obs;

  // ── Manual form controllers ────────────────────────────────────────────
  final customerSearchCtrl = TextEditingController();
  final customerAddressCtrl = TextEditingController();
  final customerPhoneCtrl   = TextEditingController();

  final quantityCtrl       = TextEditingController(text: '1');
  final amountCtrl         = TextEditingController();
  final notesCtrl          = TextEditingController();
  final slotCtrl           = TextEditingController(text: '07:00 AM');

  final RxString serviceType = 'milk'.obs;
  final RxString unit        = 'litre'.obs;

  // ── Pre-fill from arguments (e.g. opened from customer detail) ─────────
  String? get vendorId => LocalStorageService.getVendor()?.id;

  @override
  void onInit() {
    super.onInit();
    // If a CustomerModel was passed as argument, pre-select it
    final args = Get.arguments;
    if (args is CustomerModel) {
      _selectCustomer(args);
    }
  }

  // ── Customer search ────────────────────────────────────────────────────
  void onCustomerSearch(String query) {
    if (query.trim().length < 2) {
      customerSuggestions.clear();
      return;
    }
    final q = query.toLowerCase();
    customerSuggestions.assignAll(
      LocalStorageService.getCustomers()
          .where((c) =>
      c.name.toLowerCase().contains(q) ||
          c.address.toLowerCase().contains(q))
          .take(6)
          .toList(),
    );
  }

  void selectCustomerFromSuggestion(CustomerModel c) {
    customerSuggestions.clear();
    _selectCustomer(c);
  }

  void _selectCustomer(CustomerModel c) {
    selectedCustomer.value = c;
    customerSearchCtrl.text = c.name;
    serviceType.value = c.serviceTypeStr;
    // Load their subscriptions for the "from subscription" tab
    _loadCustomerSubscriptions(c);
  }

  void clearCustomer() {
    selectedCustomer.value = null;
    selectedSubscription.value = null;
    customerSearchCtrl.clear();
    customerSuggestions.clear();
    customerSubs.clear();
  }

  void _loadCustomerSubscriptions(CustomerModel c) {
    final all = LocalStorageService.getSubscriptions();
    customerSubs.assignAll(
      all.where((s) => s.customerId == c.id && s.isActive).toList(),
    );
    // Auto-select if only one subscription
    if (customerSubs.length == 1) {
      selectSubscription(customerSubs.first);
    } else {
      selectedSubscription.value = null;
    }
  }

  void selectSubscription(SubscriptionModel sub) {
    selectedSubscription.value = sub;
    // Auto-fill amount and quantity from subscription
    amountCtrl.text = sub.pricePerDelivery.toStringAsFixed(2);
    quantityCtrl.text = sub.quantity.toString();
    unit.value = sub.unit;
    serviceType.value = sub.serviceTypeStr;
    slotCtrl.text = sub.deliverySlot;
  }

  // ── Date picker ────────────────────────────────────────────────────────
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: scheduledDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) scheduledDate.value = picked;
  }

  // ── Validation ─────────────────────────────────────────────────────────
  String? _validate() {
    if (deliveryType.value == AddDeliveryType.fromSubscription) {
       if (selectedCustomer.value == null) return 'Please select a customer.';
       if (selectedSubscription.value == null) return 'Please select a subscription.';
    } else {
       if (customerSearchCtrl.text.trim().isEmpty) return 'Please enter customer name.';
    }
    
    final qty = double.tryParse(quantityCtrl.text.trim()) ?? 0;
    if (qty <= 0) return 'Enter a valid quantity.';
    final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
    if (amt <= 0) return 'Enter a valid amount.';
    return null;
  }

  // ── Submit ─────────────────────────────────────────────────────────────
  Future<void> submit() async {
    if (vendorId == null) return;

    final error = _validate();
    if (error != null) {
      Get.snackbar('Missing Info', error,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white);
      return;
    }

    isSubmitting.value = true;

    String customerId;
    String customerName;
    String customerAddress;

    if (selectedCustomer.value != null) {
      customerId = selectedCustomer.value!.id;
      customerName = selectedCustomer.value!.name;
      customerAddress = selectedCustomer.value!.address;
    } else {
      // Custom/Temporary customer
      customerName = customerSearchCtrl.text.trim();
      customerAddress = customerAddressCtrl.text.trim();
      
      if (saveAsCustomer.value) {
        // QUICK ADD CUSTOMER
        final custResult = await Get.find<CustomerRepository>().createCustomer(
          vendorId: vendorId!,
          name: customerName,
          address: customerAddress,
          phone: customerPhoneCtrl.text.trim(),
          serviceType: serviceType.value,
        );
        
        if (custResult.isSuccess) {
           customerId = custResult.data!.id;
        } else {
           customerId = 'temp_${const Uuid().v4()}';
        }
      } else {
        customerId = 'temp_${const Uuid().v4()}';
      }
    }

    final qty      = double.parse(quantityCtrl.text.trim());
    final amount   = double.parse(amountCtrl.text.trim());
    final notes    = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();

    final result = await _repo.placeExtraOrder(
      vendorId:        vendorId!,
      customerId:      customerId,
      customerName:    customerName,
      customerAddress: customerAddress,
      serviceType:     serviceType.value,
      quantity:        qty,
      unit:            unit.value,
      amount:          amount,
      notes:           notes,
    );


    isSubmitting.value = false;

    result.fold(
          (f) => Get.snackbar('Error', f.message,
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          colorText: Colors.white),
          (delivery) {
        Get.back(result: delivery);
        Get.snackbar(
          '✅ Delivery Added',
          'Delivery for $customerName on ${_formatDate(scheduledDate.value)} created.',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  @override
  void onClose() {
    customerSearchCtrl.dispose();
    quantityCtrl.dispose();
    amountCtrl.dispose();
    notesCtrl.dispose();
    slotCtrl.dispose();
    super.onClose();
  }
}
