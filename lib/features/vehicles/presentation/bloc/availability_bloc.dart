import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/availability_overview.dart';
import '../../domain/rules/availability_rules.dart';
import '../../domain/usecases/set_availability.dart';
import '../../domain/usecases/watch_availability.dart';

part 'availability_event.dart';
part 'availability_state.dart';

class AvailabilityBloc extends Bloc<AvailabilityEvent, AvailabilityState> {
  AvailabilityBloc({
    required this._watchAvailability,
    required this._setAvailability,
  }) : super(const AvailabilityLoading()) {
    on<AvailabilityStarted>(_onStarted);
    on<AvailabilityRangeChanged>(_onRangeChanged);
    on<AvailabilitySaved>(_onSaved);
    on<AvailabilityNoticeCleared>(_onNoticeCleared);
  }

  final WatchAvailability _watchAvailability;
  final SetAvailability _setAvailability;

  Future<void> _onStarted(
    AvailabilityStarted event,
    Emitter<AvailabilityState> emit,
  ) {
    emit(const AvailabilityLoading());
    return emit.forEach<Result<AvailabilityOverview>>(
      _watchAvailability(event.vehicleId),
      onData: (result) => result.when<AvailabilityState>(
        success: _withOverview,
        failure: (failure) => AvailabilityFailure(failure.message),
      ),
    );
  }

  AvailabilityState _withOverview(AvailabilityOverview overview) {
    final current = state;
    if (current is AvailabilityLoaded && current.edited) {
      return current.copyWith(overview: overview);
    }
    return AvailabilityLoaded(
      overview: overview,
      from: overview.vehicle.availableFrom,
      to: overview.vehicle.availableTo,
    );
  }

  void _onRangeChanged(
    AvailabilityRangeChanged event,
    Emitter<AvailabilityState> emit,
  ) {
    final current = state;
    if (current is! AvailabilityLoaded || current.saving) return;
    emit(
      current.copyWith(
        from: event.from,
        to: event.to,
        edited: true,
        clearNotice: true,
      ),
    );
  }

  Future<void> _onSaved(
    AvailabilitySaved event,
    Emitter<AvailabilityState> emit,
  ) async {
    final current = state;
    if (current is! AvailabilityLoaded || current.saving) return;
    if (current.problem != null) return;
    emit(current.copyWith(saving: true, clearNotice: true));
    final result = await _setAvailability(
      current.overview.vehicle.id,
      current.from,
      current.to,
    );
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(current.copyWith(edited: false, saving: false, saved: true));
      case Failure(:final failure):
        emit(current.copyWith(saving: false, notice: failure.message));
    }
  }

  void _onNoticeCleared(
    AvailabilityNoticeCleared event,
    Emitter<AvailabilityState> emit,
  ) {
    final current = state;
    if (current is AvailabilityLoaded) {
      emit(current.copyWith(clearNotice: true, saved: false));
    }
  }
}
