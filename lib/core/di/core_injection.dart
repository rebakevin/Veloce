import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/booking_lookup.dart';
import '../data/services/firebase_auth_session.dart';
import '../data/services/firestore_atomic_write.dart';
import '../data/services/firestore_audit_logger.dart';
import '../data/services/firestore_ledger_writer.dart';
import '../data/services/firestore_notification_writer.dart';
import '../data/services/momo_gateway_sim.dart';
import '../data/services/preferences_service.dart';
import '../data/services/supabase_media_storage.dart';
import '../data/services/user_lookup.dart';
import '../data/services/vehicle_lookup.dart';
import '../data/services/verification_sim.dart';
import '../domain/services/atomic_write.dart';
import '../domain/services/audit_logger.dart';
import '../domain/services/auth_session.dart';
import '../domain/services/booking_state_machine.dart';
import '../domain/services/clock.dart';
import '../domain/services/ledger_writer.dart';
import '../domain/services/media_storage.dart';
import '../domain/services/momo_gateway.dart';
import '../domain/services/notification_writer.dart';
import '../domain/services/pricing_calculator.dart';
import '../domain/services/verification_provider.dart';
import '../theme/theme_cubit.dart';
import '../widgets/app_messenger.dart';

/// Registers the shared contracts every feature codes against (TECHNICAL.md
/// §11). SDK instances are created here, at the composition root, and nowhere
/// else.
void registerCore(
  GetIt getIt, {
  required SharedPreferences preferences,
  required SupabaseClient supabase,
}) {
  getIt
    ..registerSingleton<Clock>(const SystemClock())
    ..registerSingleton<FirebaseAuth>(FirebaseAuth.instance)
    ..registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance)
    ..registerSingleton<AppMessenger>(AppMessenger())
    ..registerSingleton<PreferencesService>(PreferencesService(preferences))
    ..registerLazySingleton<ThemeCubit>(() => ThemeCubit(getIt()))
    ..registerLazySingleton<PricingCalculator>(() => const PricingCalculator())
    ..registerLazySingleton<BookingStateMachine>(
      () => const BookingStateMachine(),
    )
    ..registerLazySingleton<AtomicWriteFactory>(
      () => FirestoreAtomicWriteFactory(getIt()),
    )
    ..registerLazySingleton<LedgerWriter>(() => FirestoreLedgerWriter(getIt()))
    ..registerLazySingleton<AuditLogger>(() => FirestoreAuditLogger(getIt()))
    ..registerLazySingleton<NotificationWriter>(
      () => FirestoreNotificationWriter(getIt()),
    )
    ..registerLazySingleton<MediaStorage>(
      () => SupabaseMediaStorage(client: supabase),
    )
    ..registerLazySingleton<UserLookup>(() => UserLookup(getIt()))
    ..registerLazySingleton<VehicleLookup>(() => VehicleLookup(getIt()))
    ..registerLazySingleton<BookingLookup>(() => BookingLookup(getIt()))
    ..registerLazySingleton<MomoGatewaySim>(() => MomoGatewaySim(getIt()))
    ..registerLazySingleton<MomoGateway>(() => getIt<MomoGatewaySim>())
    ..registerLazySingleton<VerificationSim>(() => VerificationSim())
    ..registerLazySingleton<VerificationProvider>(
      () => getIt<VerificationSim>(),
    )
    ..registerLazySingleton<FirebaseAuthSession>(
      () => FirebaseAuthSession(auth: getIt(), users: getIt()),
    )
    ..registerLazySingleton<AuthSession>(() => getIt<FirebaseAuthSession>());
}
