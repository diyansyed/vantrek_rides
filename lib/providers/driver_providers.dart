import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver_profile_model.dart';
import "package:flutter_riverpod/legacy.dart";

final driverProfileProvider = StateProvider<DriverProfile?>((ref) => null);

final driverOnlineStatusProvider = StateProvider<bool>((ref) => false);

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.user);

final isDriverProvider = StateProvider<bool>((ref) => false);

final subscriptionStatusProvider = StateProvider<SubscriptionStatus>(
      (ref) => SubscriptionStatus.pending,
);

final todayEarningsProvider = StateProvider<double>((ref) => 0.0);
final weekEarningsProvider = StateProvider<double>((ref) => 0.0);
final monthEarningsProvider = StateProvider<double>((ref) => 0.0);

final pendingRequestsCountProvider = StateProvider<int>((ref) => 0);
final activeRidesProvider = StateProvider<int>((ref) => 0);

final subscriberCountProvider = StateProvider<int>((ref) => 0);

enum AppMode {
  user,
  driver,
}