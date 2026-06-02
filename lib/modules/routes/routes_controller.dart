import 'package:get/get.dart';
import '../../data/models/route_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/repositories/route_repository.dart';
import '../../data/repositories/staff_repository.dart';
import '../../services/auth_service.dart';

class RoutesController extends GetxController {
  final RouteRepository _routeRepo = Get.find();
  final StaffRepository _staffRepo = Get.find();

  final RxList<RouteModel> routes = <RouteModel>[].obs;
  final RxList<StaffModel> deliveryBoys = <StaffModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    routes.bindStream(_routeRepo.watchRoutes());
    _loadDeliveryBoys();
  }

  Future<void> _loadDeliveryBoys() async {
    final staff = await _staffRepo.getStaff();
    deliveryBoys.value = staff.where((s) => s.role == StaffRole.deliveryBoy).toList();
  }

  Future<void> addRoute(String name, String? area) async {
    try {
      isLoading.value = true;
      final newRoute = RouteModel(
        id: '', // Firestore will generate this
        vendorId: AuthService.to.vendorId,
        name: name,
        areaName: area,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _routeRepo.createRoute(newRoute);
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add route: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> assignDeliveryBoy(String routeId, StaffModel staff) async {
    try {
      final route = routes.firstWhere((r) => r.id == routeId);
      final updatedRoute = route.copyWith(
        deliveryBoyId: staff.id,
        deliveryBoyName: staff.name,
      );
      await _routeRepo.updateRoute(updatedRoute);
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign delivery boy: $e');
    }
  }
}