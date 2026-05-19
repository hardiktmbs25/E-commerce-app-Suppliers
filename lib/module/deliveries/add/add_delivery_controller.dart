// lib/module/deliveries/add/add_delivery_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/customer_model.dart';
import '../../../data/models/subscription_model.dart';

enum AddDeliveryType {
  manual,
  fromSubscription,
}

class AddDeliveryController extends GetxController {
  // ─────────────────────────────────────────────────────────
  // TYPE
  // ─────────────────────────────────────────────────────────

  final deliveryType = AddDeliveryType.manual.obs;

  // ─────────────────────────────────────────────────────────
  // LOADING
  // ─────────────────────────────────────────────────────────

  final isSubmitting = false.obs;

  // ─────────────────────────────────────────────────────────
  // FORM CONTROLLERS
  // ─────────────────────────────────────────────────────────

  final customerSearchCtrl = TextEditingController();
  final quantityCtrl = TextEditingController(text: '1');
  final amountCtrl = TextEditingController();
  final slotCtrl = TextEditingController(text: '07:00 AM');
  final notesCtrl = TextEditingController();

  // ─────────────────────────────────────────────────────────
  // REACTIVE FIELDS
  // ─────────────────────────────────────────────────────────

  final scheduledDate = DateTime.now().obs;

  final unit = 'litre'.obs;
  final serviceType = 'milk'.obs;

  // ─────────────────────────────────────────────────────────
  // CUSTOMER
  // ─────────────────────────────────────────────────────────

  final selectedCustomer = Rxn<CustomerModel>();

  final customerSuggestions = <CustomerModel>[].obs;

  // Dummy customers

  final allCustomers = <CustomerModel>[
    CustomerModel(
      id: '1',
      name: 'Rahul Sharma',
      address: 'Andheri West, Mumbai',
      phone: '9999999999',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(), vendorId: '', serviceTypeStr: '',
    ),
    CustomerModel(
      id: '2',
      name: 'Amit Patel',
      address: 'Borivali East, Mumbai',
      phone: '8888888888',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(), vendorId: '', serviceTypeStr: '',
    ),
  ];

  // ─────────────────────────────────────────────────────────
  // SUBSCRIPTIONS
  // ─────────────────────────────────────────────────────────

  final customerSubs = <SubscriptionModel>[].obs;

  final selectedSubscription = Rxn<SubscriptionModel>();

  // ─────────────────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();

    customerSuggestions.assignAll(allCustomers);
  }

  @override
  void onClose() {
    customerSearchCtrl.dispose();
    quantityCtrl.dispose();
    amountCtrl.dispose();
    slotCtrl.dispose();
    notesCtrl.dispose();

    super.onClose();
  }

  // ─────────────────────────────────────────────────────────
  // CUSTOMER SEARCH
  // ─────────────────────────────────────────────────────────

  void onCustomerSearch(String value) {
    if (value.trim().isEmpty) {
      customerSuggestions.assignAll(allCustomers);
      return;
    }

    final query = value.toLowerCase();

    customerSuggestions.assignAll(
      allCustomers.where(
            (c) =>
        c.name.toLowerCase().contains(query) ||
            c.address.toLowerCase().contains(query),
      ),
    );
  }

  void selectCustomerFromSuggestion(CustomerModel customer) {
    selectedCustomer.value = customer;

    customerSearchCtrl.text = customer.name;

    customerSuggestions.clear();

    loadCustomerSubscriptions(customer.id);
  }

  void clearCustomer() {
    selectedCustomer.value = null;

    selectedSubscription.value = null;

    customerSubs.clear();

    customerSearchCtrl.clear();

    customerSuggestions.assignAll(allCustomers);
  }

  // ─────────────────────────────────────────────────────────
  // SUBSCRIPTIONS
  // ─────────────────────────────────────────────────────────

  void loadCustomerSubscriptions(String customerId) {
    // Replace with Firestore / Repository call

    customerSubs.assignAll([
      SubscriptionModel(
        id: 'sub_1',
        customerId: customerId,
        vendorId: 'vendor_1',
        serviceTypeStr: 'milk',
        quantity: 2,
        unit: 'litre',
        frequencyStr: 'Daily',
        pricePerDelivery: 80,
        statusStr: "Active",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), customerName: 'bholo', pricePerUnit: 500, startDate: DateTime.timestamp(),
      ),
      SubscriptionModel(
        id: 'sub_2',
        customerId: customerId,
        vendorId: 'vendor_1',
        serviceTypeStr: 'newspaper',
        quantity: 1,
        unit: 'copy',
        frequencyStr: 'Daily',
        pricePerDelivery: 10,
        statusStr: "Active",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), customerName: '', pricePerUnit: 10, startDate: DateTime.timestamp(),
      ),
    ]);
  }

  void selectSubscription(SubscriptionModel sub) {
    selectedSubscription.value = sub;

    // Autofill fields
    serviceType.value = sub.serviceTypeStr;

    quantityCtrl.text = sub.quantity.toString();

    unit.value = sub.unit;

    amountCtrl.text = sub.pricePerDelivery.toStringAsFixed(0);
  }

  // ─────────────────────────────────────────────────────────
  // DATE PICKER
  // ─────────────────────────────────────────────────────────

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: scheduledDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      scheduledDate.value = picked;
    }
  }

  // ─────────────────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────────────────

  Future<void> submit() async {
    if (!_validate()) return;

    try {
      isSubmitting.value = true;

      await Future.delayed(const Duration(seconds: 1));

      final payload = {
        'deliveryType': deliveryType.value.name,
        'customerId': selectedCustomer.value?.id,
        'serviceType': serviceType.value,
        'quantity': quantityCtrl.text.trim(),
        'unit': unit.value,
        'amount': amountCtrl.text.trim(),
        'slot': slotCtrl.text.trim(),
        'notes': notesCtrl.text.trim(),
        'scheduledDate': scheduledDate.value.toIso8601String(),
        'subscriptionId': selectedSubscription.value?.id,
      };

      debugPrint('DELIVERY PAYLOAD => $payload');

      Get.snackbar(
        'Success',
        'Delivery added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      Get.back(result: true);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  // VALIDATION
  // ─────────────────────────────────────────────────────────

  bool _validate() {
    if (selectedCustomer.value == null) {
      _showError('Please select customer');
      return false;
    }

    if (deliveryType.value == AddDeliveryType.fromSubscription &&
        selectedSubscription.value == null) {
      _showError('Please select subscription');
      return false;
    }

    if (quantityCtrl.text.trim().isEmpty) {
      _showError('Please enter quantity');
      return false;
    }

    if (amountCtrl.text.trim().isEmpty) {
      _showError('Please enter amount');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    Get.snackbar(
      'Validation',
      message,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}