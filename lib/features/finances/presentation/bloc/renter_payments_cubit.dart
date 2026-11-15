import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/renter_payment_item.dart';
import '../../domain/repositories/finances_repository.dart';

sealed class RenterPaymentsState extends Equatable {
  const RenterPaymentsState();

  @override
  List<Object?> get props => [];
}

final class RenterPaymentsLoading extends RenterPaymentsState {
  const RenterPaymentsLoading();
}

final class RenterPaymentsLoaded extends RenterPaymentsState {
  const RenterPaymentsLoaded(this.items);

  final List<RenterPaymentItem> items;

  @override
  List<Object?> get props => [items];
}

final class RenterPaymentsEmpty extends RenterPaymentsState {
  const RenterPaymentsEmpty();
}

final class RenterPaymentsFailure extends RenterPaymentsState {
  const RenterPaymentsFailure(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}

class RenterPaymentsCubit extends Cubit<RenterPaymentsState> {
  RenterPaymentsCubit({
    required FinancesRepository repository,
    required AuthSession session,
  }) : _repository = repository,
       _session = session,
       super(const RenterPaymentsLoading());

  final FinancesRepository _repository;
  final AuthSession _session;

  Future<void> load() async {
    emit(const RenterPaymentsLoading());

    final renterId = _session.currentUserId;
    if (renterId == null) {
      emit(
        const RenterPaymentsFailure(
          NotFoundFailure('No authenticated renter found.'),
        ),
      );
      return;
    }

    final result = await _repository.getRenterPayments(renterId);

    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        if (value.isEmpty) {
          emit(const RenterPaymentsEmpty());
        } else {
          emit(RenterPaymentsLoaded(value));
        }
      case Failure(:final failure):
        emit(RenterPaymentsFailure(failure));
    }
  }
}
