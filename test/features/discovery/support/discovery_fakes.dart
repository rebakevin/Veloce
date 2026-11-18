import 'dart:async';

import 'package:veloce/core/domain/entities/booking.dart';
import 'package:veloce/core/domain/entities/calendar_block.dart';
import 'package:veloce/core/domain/entities/favourite.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/entities/vehicle_photo.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/auth_session.dart';
import 'package:veloce/core/domain/services/pending_review_checker.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/discovery/domain/entities/booking_request_draft.dart';
import 'package:veloce/features/discovery/domain/entities/search_query.dart';
import 'package:veloce/features/discovery/domain/entities/vehicle_card_data.dart';
import 'package:veloce/features/discovery/domain/entities/vehicle_detail.dart';
import 'package:veloce/features/discovery/domain/entities/vehicle_filters.dart';
import 'package:veloce/features/discovery/domain/repositories/favourites_repository.dart';
import 'package:veloce/features/discovery/domain/repositories/request_repository.dart';
import 'package:veloce/features/discovery/domain/repositories/search_repository.dart';

import '../../../support/builders.dart';

class FakeAuthSession implements AuthSession {
  FakeAuthSession({
    this.userId = 'renter-1',
    this.role = UserRole.renter,
    this.verified = true,
  });

  String? userId;

  @override
  UserRole? role;

  bool verified;

  @override
  String? get currentUserId => userId;

  @override
  bool get isEmailVerified => verified;

  @override
  Stream<void> get changes => const Stream.empty();
}

class FakePendingReviewChecker implements PendingReviewChecker {
  FakePendingReviewChecker({this.pending = false});

  bool pending;

  @override
  Future<bool> hasPendingReview(String userId) async => pending;
}

VehicleDetail aVehicleDetail({
  Vehicle? vehicle,
  UserAccount? owner,
  List<VehiclePhoto>? photos,
  List<CalendarBlock>? blocks,
}) {
  final car = vehicle ?? aVehicle();
  return VehicleDetail(
    vehicle: car,
    owner: owner ?? aUser(),
    photos:
        photos ??
        [
          VehiclePhoto(
            id: 'photo-1',
            vehicleId: car.id,
            url: 'https://example.com/car.jpg',
            order: 0,
            isPrimary: true,
          ),
        ],
    blocks: blocks ?? const [],
  );
}

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({
    Result<VehicleDetail>? detailResult,
    Result<List<VehicleCardData>>? searchResult,
    Result<List<VehicleCardData>>? ownerCarsResult,
  }) : detailResult = detailResult ?? Result.success(aVehicleDetail()),
       searchResult = searchResult ?? const Result.success([]),
       ownerCarsResult = ownerCarsResult ?? const Result.success([]);

  Result<VehicleDetail> detailResult;
  Result<List<VehicleCardData>> searchResult;
  Result<List<VehicleCardData>> ownerCarsResult;

  SearchQuery? lastQuery;
  VehicleFilters? lastFilters;
  final List<String> detailCalls = [];

  @override
  Future<Result<VehicleDetail>> detail(String vehicleId) async {
    detailCalls.add(vehicleId);
    return detailResult;
  }

  @override
  Future<Result<List<VehicleCardData>>> ownerCars(String ownerId) async =>
      ownerCarsResult;

  @override
  Future<Result<List<VehicleCardData>>> search({
    required SearchQuery query,
    required VehicleFilters filters,
  }) async {
    lastQuery = query;
    lastFilters = filters;
    return searchResult;
  }
}

class FakeFavouritesRepository implements FavouritesRepository {
  final StreamController<Result<List<Favourite>>> _controller =
      StreamController<Result<List<Favourite>>>.broadcast();
  final Map<String, Favourite> _favourites = {};
  bool failWrites = false;

  @override
  Stream<Result<List<Favourite>>> watch(String userId) async* {
    yield Result.success(_favourites.values.toList());
    yield* _controller.stream;
  }

  @override
  Future<Result<void>> add({
    required String userId,
    required String vehicleId,
  }) async {
    if (failWrites) return const Result.failure(NetworkFailure());
    final favourite = Favourite(
      vehicleId: vehicleId,
      userId: userId,
      createdAt: testNow,
    );
    _favourites[vehicleId] = favourite;
    _controller.add(Result.success(_favourites.values.toList()));
    return const Result.success(null);
  }

  @override
  Future<Result<void>> remove({
    required String userId,
    required String vehicleId,
  }) async {
    if (failWrites) return const Result.failure(NetworkFailure());
    _favourites.remove(vehicleId);
    _controller.add(Result.success(_favourites.values.toList()));
    return const Result.success(null);
  }

  Future<void> close() => _controller.close();
}

class FakeRequestRepository implements RequestRepository {
  FakeRequestRepository({this.locked = false, Result<Booking>? createResult})
    : createResult = createResult ?? Result.success(aBooking());

  bool locked;
  Result<Booking> createResult;
  BookingRequestDraft? lastDraft;
  String? lastRenterId;

  @override
  Future<Result<Booking>> createBooking({
    required String renterId,
    required BookingRequestDraft draft,
  }) async {
    lastRenterId = renterId;
    lastDraft = draft;
    return createResult;
  }

  @override
  Future<Result<bool>> hasActiveLock(String renterId) async =>
      Result.success(locked);
}
