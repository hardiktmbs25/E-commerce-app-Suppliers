// lib/routes/app_routes.dart
abstract class Routes {
  Routes._();
  static const splash        = '/splash';
  static const onboarding    = '/onboarding';
  static const login         = '/login';
  static const register      = '/register';
  static const forgotPassword = '/forgot-password';
  static const dashboard     = '/dashboard';
  static const customers     = '/customers';
  static const customerDetail = '/customer-detail';
  static const addCustomer   = '/add-customer';
  static const editCustomer  = '/edit-customer';
  static const subscriptions = '/subscriptions';
  static const addSubscription = '/add-subscription';
  static const subscriptionDetail = '/subscription-detail';
  static const deliveries    = '/deliveries';
  static const deliveryDetail = '/delivery-detail';
  static const billing       = '/billing';
  static const invoiceDetail = '/invoice-detail';
  static const payments      = '/payments';
  static const analytics     = '/analytics';
  static const notifications = '/notifications';
  static const profile       = '/profile';
  static const settings      = '/settings';
}