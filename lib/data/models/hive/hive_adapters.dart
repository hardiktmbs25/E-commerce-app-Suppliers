// lib/data/models/hive/hive_adapters.dart
// MODIFIED: registers the three new billing adapters.

import 'package:hive/hive.dart';

import '../invoice_model.dart';
import '../customer_model.dart';
import '../delivery_model.dart';
import '../ledger_entry_model.dart';
import '../payment_model.dart';
import '../subscription_model.dart';
import '../sync_action_model.dart';
import '../vendor_model.dart';

void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(VendorModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(CustomerModelAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SubscriptionModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(DeliveryModelAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(SyncActionModelAdapter());
  // NEW ↓
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(InvoiceModelAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(PaymentModelAdapter());
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(LedgerEntryModelAdapter());
}