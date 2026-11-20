import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/usecases/expire_bookings.dart';

sealed class ExpirySweeperState extends Equatable {
  const ExpirySweeperState();

  @override
  List<Object?> get props => [];
}

final class ExpirySweeperIdle extends ExpirySweeperState {
  const ExpirySweeperIdle();
}

final class ExpirySweeperRunning extends ExpirySweeperState {
  const ExpirySweeperRunning();
}

final class ExpirySweeperDone extends ExpirySweeperState {
  const ExpirySweeperDone(this.written);

  final int written;

  @override
  List<Object?> get props => [written];
}

final class ExpirySweeperFailure extends ExpirySweeperState {
  const ExpirySweeperFailure(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// Runs the lazy expiry sweep on app start, resume and activity load. A second
/// call while one is running is ignored.
class ExpirySweeperCubit extends Cubit<ExpirySweeperState> {
  ExpirySweeperCubit({required this._expireBookings, required this._session})
    : super(const ExpirySweeperIdle());

  final ExpireBookings _expireBookings;
  final AuthSession _session;

  Future<void> sweep() async {
    if (state is ExpirySweeperRunning) return;
    if (_session.currentUserId == null || _session.role == null) {
      emit(const ExpirySweeperDone(0));
      return;
    }
    emit(const ExpirySweeperRunning());
    final result = await _expireBookings();
    if (isClosed) return;
    emit(switch (result) {
      Success<int>(:final value) => ExpirySweeperDone(value),
      Failure<int>(:final failure) => ExpirySweeperFailure(failure),
    });
  }
}
