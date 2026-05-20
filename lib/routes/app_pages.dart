// lib/routes/app_pages.dart
import 'package:e_commerce_suppliers/module/deliveries/add/add_delivery_binding.dart';
import 'package:e_commerce_suppliers/module/deliveries/add/add_delivery_screen.dart';
import 'package:get/get.dart';
import '../module/analytics/analytics_binding.dart';
import '../module/analytics/analytics_screen.dart';
import '../module/auth/forgot_password/forgot_password_binding.dart';
import '../module/auth/forgot_password/forgot_password_screen.dart';
import '../module/auth/login/login_binding.dart';
import '../module/auth/login/login_screen.dart';
import '../module/auth/onboarding/onboarding_binding.dart';
import '../module/auth/onboarding/onboarding_screen.dart';
import '../module/auth/register/register_binding.dart';
import '../module/auth/register/register_screen.dart';
import '../module/auth/splash/splash_binding.dart';
import '../module/auth/splash/splash_screen.dart';
import '../module/billing/billing_binding.dart';
import '../module/billing/billing_screen.dart';
import '../module/customers/add/add_customer_binding.dart';
import '../module/customers/add/add_customer_screen.dart';
import '../module/customers/customers_binding.dart';
import '../module/customers/customers_screen.dart';
import '../module/customers/detail/customer_detail_binding.dart';
import '../module/customers/detail/customer_detail_screen.dart';
import '../module/dashboard/dashboard_binding.dart';
import '../module/dashboard/dashboard_screen.dart';
import '../module/deliveries/deliveries_binding.dart';
import '../module/deliveries/deliveries_screen.dart';
import '../module/deliveries/detail/delivery_detail_binding.dart';
import '../module/deliveries/detail/delivery_detail_screen.dart';
import '../module/deliveries/extra_order/extra_order_binding.dart';
import '../module/deliveries/extra_order/extra_order_screen.dart';
import '../module/deliveries/history/delivery_history_binding.dart';
import '../module/deliveries/history/delivery_history_screen.dart';
import '../module/notifications/notifications_binding.dart';
import '../module/notifications/notifications_screen.dart';
import '../module/payments/payments_binding.dart';
import '../module/payments/payments_screen.dart';
import '../module/profile/profile_binding.dart';
import '../module/profile/profile_screen.dart';
import '../module/settings/settings_binding.dart';
import '../module/settings/settings_screen.dart';
import '../module/subscriptions/add/add_subscription_binding.dart';
import '../module/subscriptions/add/add_subscription_screen.dart';
import '../module/subscriptions/global_plans/global_plans_binding.dart';
import '../module/subscriptions/global_plans/global_plans_screen.dart';
import '../module/subscriptions/subscriptions_binding.dart';
import '../module/subscriptions/subscriptions_screen.dart';
import 'app_routes.dart';

abstract class AppPages {
  static final routes = <GetPage>[
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