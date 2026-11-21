import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/data/services/vehicle_lookup.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/finance_summary.dart';
import '../../domain/enums/finance_period.dart';
import '../../domain/enums/finance_view_mode.dart';
import '../../domain/repositories/finances_repository.dart';

enum FinancesStatus { initial, loading, loaded, failure }

sealed class FinancesEvent extends Equatable {
  const FinancesEvent();

  @override
  List<Object?> get props => [];
}

final class FinancesStarted extends FinancesEvent {
  const FinancesStarted({this.vehicleId, this.period});

  final String? vehicleId;

  /// Period to open on; keeps the current one when null.
  final FinancePeriod? period;

  @override
  List<Object?> get props => [vehicleId, period];
}

final class FinancesPeriodChanged extends FinancesEvent {
  const FinancesPeriodChanged(this.period);

  final FinancePeriod period;

  @override
  List<Object?> get props => [period];
}

final class FinancesViewModeChanged extends FinancesEvent {
  const FinancesViewModeChanged(this.viewMode);

  final FinanceViewMode viewMode;

  @override
  List<Object?> get props => [viewMode];
}

final class FinancesRefreshed extends FinancesEvent {
  const FinancesRefreshed();
}

class FinancesState extends Equatable {
  const FinancesState({
    this.status = FinancesStatus.initial,
    this.period = FinancePeriod.thisMonth,
    this.viewMode = FinanceViewMode.chart,
    this.vehicleId,
    this.vehicle,
    this.summary,
    this.failure,
  });

  final FinancesStatus status;
  final FinancePeriod period;
  final FinanceViewMode viewMode;
  final String? vehicleId;
  final Vehicle? vehicle;
  final FinanceSummary? summary;
  final AppFailure? failure;

  FinancesState copyWith({
    FinancesStatus? status,
    FinancePeriod? period,
    FinanceViewMode? viewMode,
    String? vehicleId,
    Vehicle? vehicle,
    FinanceSummary? summary,
    AppFailure? failure,
  }) {
    return FinancesState(
      status: status ?? this.status,
      period: period ?? this.period,
      viewMode: viewMode ?? this.viewMode,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicle: vehicle ?? this.vehicle,
      summary: summary ?? this.summary,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [
    status,
    period,
    viewMode,
    vehicleId,
    vehicle,
    summary,
    failure,
  ];
}

class FinancesBloc extends Bloc<FinancesEvent, FinancesState> {
  FinancesBloc({
    required this._repository,
    required this._session,
    required this._vehicleLookup,
    String? vehicleId,
  }) : super(FinancesState(vehicleId: vehicleId)) {
    on<FinancesStarted>(_onStarted);
    on<FinancesPeriodChanged>(_onPeriodChanged);
    on<FinancesViewModeChanged>(_onViewModeChanged);
    on<FinancesRefreshed>(_onRefreshed);
  }

  final FinancesRepository _repository;
  final AuthSession _session;
  final VehicleLookup _vehicleLookup;

  Future<void> _onStarted(
    FinancesStarted event,
    Emitter<FinancesState> emit,
  ) async {
    final vehicleId = event.vehicleId ?? state.vehicleId;
    final period = event.period ?? state.period;
    Vehicle? vehicle;
    if (vehicleId != null) {
      final res = await _vehicleLookup.byId(vehicleId);
      if (res is Success<Vehicle>) {
        vehicle = res.value;
      }
    }

    emit(
      state.copyWith(
        status: FinancesStatus.loading,
        period: period,
        vehicleId: vehicleId,
        vehicle: vehicle,
      ),
    );

    await _loadSummary(emit, period, vehicleId);
  }

  Future<void> _onPeriodChanged(
    FinancesPeriodChanged event,
    Emitter<FinancesState> emit,
  ) async {
    if (event.period == state.period && state.status == FinancesStatus.loaded) {
      return;
    }
    emit(state.copyWith(status: FinancesStatus.loading, period: event.period));
    await _loadSummary(emit, event.period, state.vehicleId);
  }

  void _onViewModeChanged(
    FinancesViewModeChanged event,
    Emitter<FinancesState> emit,
  ) {
    emit(state.copyWith(viewMode: event.viewMode));
  }

  Future<void> _onRefreshed(
    FinancesRefreshed event,
    Emitter<FinancesState> emit,
  ) async {
    emit(state.copyWith(status: FinancesStatus.loading));
    await _loadSummary(emit, state.period, state.vehicleId);
  }

  Future<void> _loadSummary(
    Emitter<FinancesState> emit,
    FinancePeriod period,
    String? vehicleId,
  ) async {
    final ownerId = _session.currentUserId;
    if (ownerId == null) {
      emit(
        state.copyWith(
          status: FinancesStatus.failure,
          failure: const NotFoundFailure('No authenticated owner found.'),
        ),
      );
      return;
    }

    final result = await _repository.getOwnerFinances(
      ownerId: ownerId,
      period: period,
      vehicleId: vehicleId,
    );

    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(status: FinancesStatus.loaded, summary: value));
      case Failure(:final failure):
        emit(state.copyWith(status: FinancesStatus.failure, failure: failure));
    }
  }
}
