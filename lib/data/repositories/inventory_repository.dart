import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../models/inventory_model.dart';

class InventoryRepository extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String get _vendorId => AuthService.to.vendorId;

  CollectionReference get _inventoryCol => _firestore.collection(AppConstants.colInventory);

  Future<void> updateStock(InventoryModel item) async {
    await _inventoryCol.doc(item.id).set(item.toFirestore(), SetOptions(merge: true));
  }

  Stream<List<InventoryModel>> watchInventory() {
    return _inventoryCol
        .where('vendorId', isEqualTo: _vendorId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => InventoryModel.fromFirestore(doc)).toList());
  }

  Future<void> addStockMovement(String productId, double amount, String type) async {
    // type: 'in' or 'out'
    await _firestore.collection('inventory_movements').add({
      'vendorId': _vendorId,
      'productId': productId,
      'amount': amount,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}