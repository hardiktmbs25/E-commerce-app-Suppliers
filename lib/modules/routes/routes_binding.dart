import 'package:get/get.dart';
import '../../data/repositories/route_repository.dart';
import '../../data/repositories/staff_repository.dart';
import 'routes_controller.dart';

class RoutesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RouteRepository>(() => RouteRepository());
    Get.lazyPut<StaffRepository>(() => StaffRepository());
    Get.lazyPut<RoutesController>(() => RoutesController());
  }
}