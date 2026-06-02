// lib/data/models/hive/hive_adapters.dart

import 'package:hive/hive.dart';

import '../customer_model.dart';
import '../delivery_area_model.dart';
import '../delivery_model.dart';
import '../expense_model.dart';
import '../inventory_model.dart';
import '../invoice_model.dart';
import '../ledger_entry_model.dart';
import '../payment_model.dart';
import '../plan_model.dart';
import '../route_model.dart';
import '../staff_model.dart';
import '../subscription_model.dart';
import '../sync_action_model.dart';
import '../time_slot_model.dart';
import '../vendor_model.dart';

void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(0))  Hive.registerAdapter(VendorModelAdapter());
  if (!Hive.isAdapterRegistered(1))  Hive.registerAdapter(CustomerModelAdapter());
  if (!Hive.isAdapterRegistered(2))  Hive.registerAdapter(SubscriptionModelAdapter());
  if (!Hive.isAdapterRegistered(3))  Hive.registerAdapter(DeliveryModelAdapter());
  if (!Hive.isAdapterRegistered(4))  Hive.registerAdapter(SyncActionModelAdapter());
  if (!Hive.isAdapterRegistered(5))  Hive.registerAdapter(InvoiceModelAdapter());
  if (!Hive.isAdapterRegistered(6))  Hive.registerAdapter(PaymentModelAdapter());
  if (!Hive.isAdapterRegistered(7))  Hive.registerAdapter(LedgerEntryModelAdapter());
  if (!Hive.isAdapterRegistered(8))  Hive.registerAdapter(RouteModelAdapter());
  if (!Hive.isAdapterRegistered(9))  Hive.registerAdapter(StaffModelAdapter());
  if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(InventoryModelAdapter());
  if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(ExpenseModelAdapter());
  if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(TimeSlotModelAdapter());
  if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(DeliveryAreaModelAdapter());
  if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(PlanModelAdapter());
}