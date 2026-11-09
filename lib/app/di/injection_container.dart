import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:veloce/core/di/core_injection.dart';
import 'package:veloce/features/auth/auth.dart';
import 'package:veloce/features/booking/booking.dart';
import 'package:veloce/features/discovery/discovery.dart';
import 'package:veloce/features/finances/finances.dart';
import 'package:veloce/features/handover/handover.dart';
import 'package:veloce/features/notifications/notifications.dart';
import 'package:veloce/features/profile/profile.dart';
import 'package:veloce/features/reviews/reviews.dart';
import 'package:veloce/features/vehicles/vehicles.dart';

/// Composition root: shared services first, then each feature registers itself.
void configureDependencies(
  GetIt getIt, {
  required SharedPreferences preferences,
  required SupabaseClient supabase,
}) {
  registerCore(getIt, preferences: preferences, supabase: supabase);
  registerAuth(getIt);
  registerProfile(getIt);
  registerVehicles(getIt);
  registerDiscovery(getIt);
  registerBooking(getIt);
  registerHandover(getIt);
  registerFinances(getIt);
  registerReviews(getIt);
  registerNotifications(getIt);
}
