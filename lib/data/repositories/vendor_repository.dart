// lib/data/repositories/vendor_repository.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/logger.dart';
import '../../services/auth_service.dart';
import '../../services/local_storage_service.dart';
import '../models/vendor_model.dart';

/// Manages all vendor profile CRUD operations.
///
/// WHY REPOSITORY EXISTS:
/// Controllers should never know whether data comes from Firestore or Hive.
/// The repository decides the data source based on connectivity, caches results
/// locally, and returns domain models — not raw Firestore documents.
class VendorRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _auth = Get.find<AuthService>();

  CollectionReference get _col => _db.collection(AppConstants.colVendors);

  // ── Create vendor profile after registration ───────────────────────────
  Future<Result<VendorModel>> createVendor({
    required String name,
    required String businessName,
    required String email,
    required String phone,
    required String address,
    required String city,
    required String serviceType,
    File? profileImage,
  }) async {
    try {
      final uid = _auth.uid!;
      String? imageUrl;

      if (profileImage != null) {
        imageUrl = await _uploadProfileImage(uid, profileImage);
      }

      final now = DateTime.now();
      final vendor = VendorModel(
        id:             uid,
        name:           name,
        businessName:   businessName,
        email:          email,
        phone:          phone,
        address:        address,
        city:           city,
        serviceTypeStr: serviceType,
        profileImageUrl: imageUrl,
        createdAt:      now,
        updatedAt:      now,
      );

      await _col.doc(uid).set(vendor.toFirestore());
      await LocalStorageService.saveVendor(vendor);
      await LocalStorageService.setVendorId(uid);

      AppLogger.i('VendorRepository: vendor created $uid');
      return Result.success(vendor);
    } catch (e, s) {
      AppLogger.e('VendorRepository.createVendor', e, s);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ── Fetch vendor (local-first) ─────────────────────────────────────────
  Future<Result<VendorModel>> fetchVendor(String uid) async {
    // 1. Return local cache immediately
    final cached = LocalStorageService.getVendor();
    if (cached != null && cached.id == uid) {
      return Result.success(cached);
    }

    // 2. Fetch from Firestore
    try {
      final doc = await _col.doc(uid).get();
      if (!doc.exists) return Result.failure(const FirestoreFailure('Vendor not found'));
      final vendor = VendorModel.fromFirestore(doc);
      await LocalStorageService.saveVendor(vendor);
      return Result.success(vendor);
    } catch (e) {
      AppLogger.e('VendorRepository.fetchVendor', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ── Realtime stream (for dashboard live updates) ───────────────────────
  Stream<VendorModel?> watchVendor(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final vendor = VendorModel.fromFirestore(doc);
      LocalStorageService.saveVendor(vendor); // Keep cache in sync
      return vendor;
    }).handleError((e) {
      AppLogger.e('watchVendor error', e);
    });
  }

  // ── Update vendor profile ──────────────────────────────────────────────
  Future<Result<void>> updateVendor(VendorModel vendor, {File? newImage}) async {
    try {
      String? imageUrl = vendor.profileImageUrl;
      if (newImage != null) {
        imageUrl = await _uploadProfileImage(vendor.id, newImage);
      }

      final updated = vendor.copyWith(profileImageUrl: imageUrl);
      await _col.doc(vendor.id).update(updated.toFirestore());
      await LocalStorageService.saveVendor(updated);
      return const Result.success(null);
    } catch (e) {
      AppLogger.e('VendorRepository.updateVendor', e);
      return Result.failure(FirestoreFailure(e.toString()));
    }
  }

  // ── Upload profile image to Firebase Storage ───────────────────────────
  Future<String> _uploadProfileImage(String uid, File image) async {
    final ref = _storage.ref('vendors/$uid/profile_${const Uuid().v4()}.jpg');
    await ref.putFile(image, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  // ── Update FCM token ───────────────────────────────────────────────────
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _col.doc(uid).update({'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      AppLogger.e('updateFcmToken error', e);
    }
  }
}
