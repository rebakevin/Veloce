import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/features/profile/domain/entities/public_profile.dart';
import 'package:veloce/features/profile/domain/repositories/profile_repository.dart';

sealed class PublicProfileState extends Equatable {
  const PublicProfileState();

  @override
  List<Object?> get props => [];
}

final class PublicProfileLoading extends PublicProfileState {
  const PublicProfileLoading();
}

final class PublicProfileLoaded extends PublicProfileState {
  const PublicProfileLoaded(this.profile);

  final PublicProfile profile;

  @override
  List<Object?> get props => [profile];
}

/// No user with that id.
final class PublicProfileNotFound extends PublicProfileState {
  const PublicProfileNotFound();
}

final class PublicProfileFailure extends PublicProfileState {
  const PublicProfileFailure(this.error);

  final AppFailure error;

  @override
  List<Object?> get props => [error];
}

/// Public profile behind `/user/:id`. Never holds contact details.
class PublicProfileCubit extends Cubit<PublicProfileState> {
  PublicProfileCubit({required this._repository, required this._userId})
    : super(const PublicProfileLoading());

  final ProfileRepository _repository;
  final String _userId;

  /// Loads the profile. Call on creation and from the Retry button.
  Future<void> load() async {
    emit(const PublicProfileLoading());
    final result = await _repository.getPublicProfile(_userId);
    if (isClosed) return;
    emit(switch (result) {
      Success(:final value) => PublicProfileLoaded(value),
      Failure(failure: NotFoundFailure()) => const PublicProfileNotFound(),
      Failure(:final failure) => PublicProfileFailure(failure),
    });
  }
}
