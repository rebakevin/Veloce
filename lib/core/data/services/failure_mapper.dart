import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../error/app_failure.dart';

/// Translates SDK exceptions into [AppFailure]s at the data boundary, and logs
/// each one once with its stack trace. Nothing above `data` sees SDK types.
AppFailure mapToFailure(Object error, StackTrace stackTrace) {
  final failure = switch (error) {
    TimeoutException() || SocketException() => const NetworkFailure(),
    FirebaseException(:final code) when code == 'unavailable' =>
      const NetworkFailure(),
    FirebaseException(:final code) when code == 'permission-denied' =>
      const PermissionFailure(),
    FirebaseException(:final code) when code == 'not-found' =>
      const NotFoundFailure(),
    FirebaseAuthException(:final code) when code == 'network-request-failed' =>
      const NetworkFailure(),
    StorageException() => const UnknownFailure(
      'The file could not be uploaded. Please try again.',
    ),
    _ => const UnknownFailure(),
  };
  log(
    'Operation failed',
    name: 'failure_mapper',
    error: error,
    stackTrace: stackTrace,
  );
  return failure;
}
