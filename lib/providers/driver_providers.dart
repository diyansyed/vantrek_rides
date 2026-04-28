import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_profile_model.dart';
import "package:flutter_riverpod/legacy.dart";
// Current driver profile provider
final driverProfileProvider = StateProvider<DriverProfile?>((ref) => null);

// Driver online/offline status
final driverOnlineStatusProvider = StateProvider<bool>((ref) => false);

// Current app mode (user or driver)
final appModeProvider = StateProvider<AppMode>((ref) => AppMode.user);

// Is user a driver?
final isDriverProvider = StateProvider<bool>((ref) => false);

// Subscription status
final subscriptionStatusProvider = StateProvider<SubscriptionStatus>(
      (ref) => SubscriptionStatus.pending,
);

// Earnings providers
final todayEarningsProvider = StateProvider<double>((ref) => 0.0);
final weekEarningsProvider = StateProvider<double>((ref) => 0.0);
final monthEarningsProvider = StateProvider<double>((ref) => 0.0);

// Active rides count
// Ride Request Providers
final pendingRequestsCountProvider = StateProvider<int>((ref) => 0);
final activeRidesProvider = StateProvider<int>((ref) => 0);

// Subscription Providers
final subscriberCountProvider = StateProvider<int>((ref) => 0);

enum AppMode {
  user,
  driver,
}