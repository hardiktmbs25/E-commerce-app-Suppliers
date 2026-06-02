// lib/routes/app_pages.dart

import 'package:e_commerce_suppliers/modules/deliveries/add/add_delivery_binding.dart';
import 'package:e_commerce_suppliers/modules/deliveries/add/add_delivery_screen.dart';
import 'package:get/get.dart';
import '../data/repositories/billing_repository.dart';
import '../modules/analytics/analytics_binding.dart';
import '../modules/analytics/analytics_screen.dart';
import '../modules/auth/forgot_password/forgot_password_binding.dart';
import '../modules/auth/forgot_password/forgot_password_screen.dart';
import '../modules/auth/login/login_binding.dart';
import '../modules/auth/login/login_screen.dart';
import '../modules/auth/onboarding/onboarding_binding.dart';
import '../modules/auth/onboarding/onboarding_screen.dart';
import '../modules/auth/register/register_binding.dart';
import '../modules/auth/register/register_screen.dart';
import '../modules/auth/splash/splash_binding.dart';
import '../modules/auth/splash/splash_screen.dart';
import '../modules/billing/billing_binding.dart';
import '../modules/billing/billing_screen.dart';
import '../modules/billing/customer_ledger_screen.dart';
import '../modules/billing/payment_history_screen.dart';
import '../modules/customers/add/add_customer_binding.dart';
import '../modules/customers/add/add_customer_screen.dart';
import '../modules/customers/customers_binding.dart';
import '../modules/customers/customers_screen.dart';
import '../modules/customers/detail/customer_detail_binding.dart';
import '../modules/customers/detail/customer_detail_screen.dart';
import '../modules/dashboard/dashboard_binding.dart';
import '../modules/dashboard/dashboard_screen.dart';
import '../modules/deliveries/deliveries_binding.dart';
import '../modules/deliveries/deliveries_screen.dart';
import '../modules/deliveries/detail/delivery_detail_binding.dart';
import '../modules/deliveries/detail/delivery_detail_screen.dart';
import '../modules/deliveries/extra_order/extra_order_binding.dart';
import '../modules/deliveries/extra_order/extra_order_screen.dart';
import '../modules/deliveries/history/delivery_history_binding.dart';
import '../modules/deliveries/history/delivery_history_screen.dart';
import '../modules/notifications/notifications_binding.dart';
import '../modules/notifications/notifications_screen.dart';
import '../modules/payments/payments_binding.dart';
import '../modules/payments/payments_screen.dart';
import '../modules/profile/profile_binding.dart';
import '../modules/profile/profile_screen.dart';
import '../modules/settings/settings_binding.dart';
import '../modules/settings/settings_screen.dart';
import '../modules/subscriptions/add/add_subscription_binding.dart';
import '../modules/subscriptions/add/add_subscription_screen.dart';
import '../modules/subscriptions/global_plans/global_plans_binding.dart';
import '../modules/subscriptions/global_plans/global_plans_screen.dart';
import '../modules/subscriptions/subscriptions_binding.dart';
import '../modules/subscriptions/subscriptions_screen.dart';
import '../modules/routes/routes_binding.dart';
import '../modules/routes/routes_screen.dart';
import '../modules/staff/staff_binding.dart';
import '../modules/staff/staff_screen.dart';
import '../modules/inventory/inventory_binding.dart';
import '../modules/inventory/inventory_screen.dart';
import '../modules/expenses/expenses_binding.dart';
import '../modules/expenses/expenses_screen.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: Routes.routeList,
      page: () => const RoutesScreen(),
      binding: RoutesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.staffList,
      page: () => const StaffScreen(),
      binding: StaffBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.inventory,
      page: () => const InventoryScreen(),
      binding: InventoryBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.expenses,
      page: () => const ExpensesScreen(),
      binding: ExpensesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.customerLedger,
      page: () => const CustomerLedgerScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<BillingRepository>()) {
          Get.lazyPut<BillingRepository>(() => BillingRepository(), fenix: true);
        }
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.paymentHistory,
      page: () => const PaymentHistoryScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<BillingRepository>()) {
          Get.lazyPut<BillingRepository>(() => BillingRepository(), fenix: true);
        }
      }),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.onboarding,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterScreen(),
      binding: RegisterBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardScreen(),
      binding: DashboardBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.customers,
      page: () => const CustomersScreen(),
      binding: CustomersBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.addCustomer,
      page: () => const AddCustomerScreen(),
      binding: AddCustomerBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.customerDetail,
      page: () => const CustomerDetailScreen(),
      binding: CustomerDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.subscriptions,
      page: () => const SubscriptionsScreen(),
      binding: SubscriptionsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.addSubscription,
      page: () => const AddSubscriptionScreen(),
      binding: AddSubscriptionBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.globalPlans,
      page: () => const GlobalPlansScreen(),
      binding: GlobalPlansBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.deliveries,
      page: () => const DeliveriesScreen(),
      binding: DeliveriesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.billing,
      page: () => const BillingScreen(),
      binding: BillingBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.addDelivery,
      page: () => const AddDeliveryScreen(),
      binding: AddDeliveryBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.deliveryDetail,
      page: () => const DeliveryDetailScreen(),
      binding: DeliveryDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.deliveryHistory,
      page: () => const DeliveryHistoryScreen(),
      binding: DeliveryHistoryBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.extraOrder,
      page: () => const ExtraOrderScreen(),
      binding: ExtraOrderBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.payments,
      page: () => const PaymentsScreen(),
      binding: PaymentsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.analytics,
      page: () => const AnalyticsScreen(),
      binding: AnalyticsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileScreen(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}