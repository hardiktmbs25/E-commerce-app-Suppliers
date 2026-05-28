import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../models/route_model.dart';

class RouteRepository extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String get _vendorId => AuthService.to.vendorId;

  CollectionReference get _routeCol => _firestore.collection(AppConstants.colRoutes);

  Future<void> createRoute(RouteModel route) async {
    await _routeCol.add(route.toFirestore());
  }

  Future<void> updateRoute(RouteModel route) async {
    await _routeCol.doc(route.id).update(route.toFirestore());
  }

  Future<void> deleteRoute(String id) async {
    await _routeCol.doc(id).delete();
  }

  Stream<List<RouteModel>> watchRoutes() {
    return _routeCol
        .where('vendorId', isEqualTo: _vendorId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RouteModel.fromFirestore(doc)).toList());
  }

  Future<List<RouteModel>> getRoutes() async {
    final query = await _routeCol.where('vendorId', isEqualTo: _vendorId).get();
    return query.docs.map((doc) => RouteModel.fromFirestore(doc)).toList();
  }
}