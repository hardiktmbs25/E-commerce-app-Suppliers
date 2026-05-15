// lib/data/repositories/customer_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../services/connectivity_service.dart';
import '../../services/local_storage_service.dart';
import '../models/customer_model.dart';
import '../models/sync_action_model.dart';

class CustomerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ConnectivityService _connectivity = Get.find<ConnectivityService>();

  String _col(String vendorId) => '${AppConstants.colVendors}/$vendorId/${AppConstants.colCustomers}';

  // ── Local-first fetch ──────────────────────────────────────────────────
  List<CustomerModel> getLocalCustomers() => LocalStorageService.getCustomers();

  // ── Realtime stream (primary data source for CustomerList screen) ──────
  Stream<List<CustomerModel>> watchCustomers(String vendorId) {
    return _db.collection(_col(vendorId))
        .orderBy('name')
        .snapshots()
        .map((snap) {
      final customers = snap.docs
          .map((d) => CustomerModel.fromFirestore(d))
          .toList();
      // Keep local cache in sync with stream data
      LocalStorageService.saveCustomers(customers);
      return customers;
    })
        .handleError((e) {
      AppLogger.e('watchCustomers error', e);
      // Fallback to local cache on stream error
      return LocalStorageService.getCustomers();
    });
  }

  // ── Paginated fetch (for analytics/batch billing) ─────────────────────
  Future<Result<List<CustomerModel>>> fetchCustomers(
      String vendorId, {
        DocumentSnapshot? lastDoc,
        int limit = AppConstants.pageSize,
        String? statusFilter,
      }) async {
    try {
      var query = _db
          .collection(_col(vendorId))
          .orderBy('name')
          .limit(limit);

      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter) as Query<Map<String, dynamic>>;
      }
      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc) as Query<Map<String, dynamic>>;
      }

      final snap = await query.get();
      final customers = snap.docs.map((d) => CustomerModel.fromFirestore(d)).toList();
      return Result.success(customers);
    } catch (e) {
      AppLogger.e('fetchCustomers error', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ── Create customer (offline-capable) ─────────────────────────────────
  Future<Result<CustomerModel>> createCustomer({
    required String vendorId,
    required String name,
    required String phone,
    required String address,
    required String serviceType,
    String? alternatePhone,
    String? landmark,
    String? routeId,
    String? routeName,
    String? notes,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final customer = CustomerModel(
      id:             id,
      vendorId:       vendorId,
      name:           name,
      phone:          phone,
      alternatePhone: alternatePhone,
      address:        address,
      landmark:       landmark,
      routeId:        routeId,
      routeName:      routeName,
      serviceTypeStr: serviceType,
      notes:          notes,
      createdAt:      now,
      updatedAt:      now,
    );

    // 1. Always save locally first (optimistic)
    await LocalStorageService.saveCustomer(customer);

    if (_connectivity.isOnline.value) {
      // 2a. Online: write directly to Firestore
      try {
        await _db.collection(_col(vendorId)).doc(id).set(customer.toFirestore());
        AppLogger.i('Customer created online: $id');
        return Result.success(customer);
      } catch (e) {
        // Firestore failed — enqueue for later sync
        await _enqueueCreate(vendorId, id, customer);
        return Result.success(customer); // Still return success (local is saved)
      }
    } else {
      // 2b. Offline: enqueue sync action
      await _enqueueCreate(vendorId, id, customer);
      AppLogger.i('Customer queued offline: $id');
      return Result.success(customer);
    }
  }

  // ── Update customer ────────────────────────────────────────────────────
  Future<Result<void>> updateCustomer(String vendorId, CustomerModel customer) async {
    await LocalStorageService.saveCustomer(customer);

    if (_connectivity.isOnline.value) {
      try {
        await _db.collection(_col(vendorId)).doc(customer.id).update(customer.toFirestore());
        return const Result.success(null);
      } catch (e) {
        await _enqueueUpdate(vendorId, customer);
        return const Result.success(null);
      }
    } else {
      await _enqueueUpdate(vendorId, customer);
      return const Result.success(null);
    }
  }

  // ── Delete customer (soft-delete via status) ───────────────────────────
  Future<Result<void>> deleteCustomer(String vendorId, String customerId) async {
    await LocalStorageService.deleteCustomer(customerId);

    if (_connectivity.isOnline.value) {
      try {
        await _db.collection(_col(vendorId)).doc(customerId).delete();
        return const Result.success(null);
      } catch (e) {
        await _enqueueDelete(vendorId, customerId);
        return const Result.success(null);
      }
    } else {
      await _enqueueDelete(vendorId, customerId);
      return const Result.success(null);
    }
  }

  // ── Search (local-first for offline support) ───────────────────────────
  List<CustomerModel> searchLocal(String query) {
    final q = query.toLowerCase();
    return LocalStorageService.getCustomers()
        .where((c) =>
    c.name.toLowerCase().contains(q) ||
        c.phone.contains(q) ||
        c.address.toLowerCase().contains(q))
        .toList();
  }

  // ── Sync queue helpers ─────────────────────────────────────────────────
  Future<void> _enqueueCreate(
      String vendorId, String id, CustomerModel c) async {
    final action = SyncActionModel(
      id:            const Uuid().v4(),
      actionTypeStr: SyncActionType.createCustomer.name,
      collection:    _col(vendorId),
      documentId:    id,
      payload:       c.toFirestore(),
      createdAt:     DateTime.now(),
      localId:       id,
    );
    await LocalStorageService.enqueueSyncAction(action);
  }

  Future<void> _enqueueUpdate(String vendorId, CustomerModel c) async {
    final action = SyncActionModel(
      id:            const Uuid().v4(),
      actionTypeStr: SyncActionType.updateCustomer.name,
      collection:    _col(vendorId),
      documentId:    c.id,
      payload:       c.toFirestore(),
      createdAt:     DateTime.now(),
    );
    await LocalStorageService.enqueueSyncAction(action);
  }

  Future<void> _enqueueDelete(String vendorId, String customerId) async {
    final action = SyncActionModel(
      id:            const Uuid().v4(),
      actionTypeStr: SyncActionType.deleteCustomer.name,
      collection:    _col(vendorId),
      documentId:    customerId,
      payload:       {},
      createdAt:     DateTime.now(),
    );
    await LocalStorageService.enqueueSyncAction(action);
  }
}