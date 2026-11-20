import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/domain/services/price_quote.dart';
import 'package:veloce/core/domain/services/pricing_calculator.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';

import '../../domain/entities/vehicle_detail.dart';
import '../../domain/services/availability_rules.dart';
import '../../domain/usecases/get_vehicle_detail.dart';

part 'car_detail_event.dart';
part 'car_detail_state.dart';

/// Loads a car and keeps the selected dates, live quote and terms in one place.
class CarDetailBloc extends Bloc<CarDetailEvent, CarDetailState> {
  CarDetailBloc({
    required this._getDetail,
    required this._session,
    required this._pricing,
    required this._clock,
    required this.vehicleId,
    this.initialStart,
    this.initialEnd,
    this.rules = const AvailabilityRules(),
  }) : super(const CarDetailLoading()) {
    on<CarDetailStarted>(_onLoad);
    on<CarDetailRetried>(_onLoad);
    on<CarDetailDatesChanged>(_onDatesChanged);
    on<CarDetailTermsChanged>(_onTermsChanged);
  }

  final String vehicleId;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final GetVehicleDetail _getDetail;
  final AuthSession _session;
  final PricingCalculator _pricing;
  final Clock _clock;
  final AvailabilityRules rules;

  Future<void> _onLoad(
    CarDetailEvent event,
    Emitter<CarDetailState> emit,
  ) async {
    emit(const CarDetailLoading());
    final result = await _getDetail(vehicleId);
    if (isClosed) return;
    if (result case Failure(:final failure)) {
      emit(CarDetailFailure(failure));
      return;
    }
    final detail = (result as Success<VehicleDetail>).value;
    final isOwner = detail.vehicle.ownerId == _session.currentUserId;
    final dates = _chosenDates(detail) ?? _defaultDates(detail);
    final quote = dates == null ? null : _quote(detail, dates.$1, dates.$2);
    emit(
      CarDetailLoaded(
        detail: detail,
        isOwner: isOwner,
        start: dates?.$1,
        end: dates?.$2,
        quote: quote,
      ),
    );
  }

  (DateTime, DateTime)? _chosenDates(VehicleDetail detail) {
    final start = initialStart;
    final end = initialEnd;
    if (start == null || end == null) return null;
    final now = _clock.now();
    if (rules.isPast(start, now)) return null;
    if (end.isBefore(start)) return null;
    if (!rules.isWithinWindow(detail.vehicle, start, end)) return null;
    if (!rules.isFree(detail.blocks, start, end)) return null;
    return (start, end);
  }

  (DateTime, DateTime)? _defaultDates(VehicleDetail detail) {
    final today = rules.day(_clock.now());
    final from = detail.vehicle.availableFrom;
    final to = detail.vehicle.availableTo;
    if (from == null || to == null) return null;
    final start = rules.day(from).isBefore(today) ? today : rules.day(from);
    final end = start.add(const Duration(days: 1));
    if (end.isAfter(rules.day(to))) return null;
    if (!rules.isFree(detail.blocks, start, end)) return null;
    return (start, end);
  }

  PriceQuote _quote(VehicleDetail detail, DateTime start, DateTime end) {
    final vehicle = detail.vehicle;
    return _pricing.quote(
      dailyPrice: vehicle.dailyPrice,
      longRates: vehicle.longRates,
      cautionFee: vehicle.cautionFee,
      start: start,
      end: end,
    );
  }

  void _onDatesChanged(
    CarDetailDatesChanged event,
    Emitter<CarDetailState> emit,
  ) {
    final state = this.state;
    if (state is! CarDetailLoaded) return;
    final vehicle = state.detail.vehicle;
    final now = _clock.now();
    String? error;
    if (rules.isPast(event.start, now)) {
      error = 'Choose a pickup date from today onwards.';
    } else if (event.end.isBefore(event.start)) {
      error = 'The return date must be after the pickup date.';
    } else if (!rules.isWithinWindow(vehicle, event.start, event.end)) {
      error = 'These dates are outside the owner’s availability.';
    } else if (!rules.isFree(state.detail.blocks, event.start, event.end)) {
      error = 'Those dates are already booked.';
    }
    if (error != null) {
      emit(
        state.copyWith(
          start: event.start,
          end: event.end,
          dateError: error,
          clearQuote: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        start: event.start,
        end: event.end,
        quote: _quote(state.detail, event.start, event.end),
        clearDateError: true,
      ),
    );
  }

  void _onTermsChanged(
    CarDetailTermsChanged event,
    Emitter<CarDetailState> emit,
  ) {
    final state = this.state;
    if (state is! CarDetailLoaded) return;
    emit(state.copyWith(termsAccepted: event.accepted));
  }
}
