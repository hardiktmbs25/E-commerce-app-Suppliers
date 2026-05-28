import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../models/staff_model.dart';

class StaffRepository extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String get _vendorId => AuthService.to.vendorId;

  CollectionReference get _staffCol => _firestore.collection(AppConstants.colStaff);

  Future<void> addStaff(StaffModel staff) async {
    await _staffCol.add(staff.toFirestore());
  }

  Future<void> updateStaff(StaffModel staff) async {
    await _staffCol.doc(staff.id).update(staff.toFirestore());
  }

  Stream<List<StaffModel>> watchStaff() {
    return _staffCol
        .where('vendorId', isEqualTo: _vendorId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => StaffModel.fromFirestore(doc)).toList());
  }

  Future<List<StaffModel>> getStaff() async {
    final query = await _staffCol.where('vendorId', isEqualTo: _vendorId).get();
    return query.docs.map((doc) => StaffModel.fromFirestore(doc)).toList();
  }
}