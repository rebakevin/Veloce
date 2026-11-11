import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:veloce/core/domain/entities/contact.dart';
import 'package:veloce/core/domain/entities/licence.dart';
import 'package:veloce/core/domain/entities/owner_identity.dart';
import 'package:veloce/core/domain/entities/payout_method.dart';
import 'package:veloce/core/domain/entities/user_account.dart';
import 'package:veloce/core/domain/enums/user_role.dart';
import 'package:veloce/core/domain/services/clock.dart';
import 'package:veloce/core/error/app_failure.dart';
import 'package:veloce/core/error/result.dart';
import 'package:veloce/core/validation/validators.dart';
import 'package:veloce/features/profile/domain/entities/identity_submission.dart';
import 'package:veloce/features/profile/domain/entities/licence_submission.dart';
import 'package:veloce/features/profile/domain/entities/profile_update.dart';
import 'package:veloce/features/profile/domain/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// The signed-in user's own profile for the Profile tab and the edit screens.
///
/// Dispatch [ProfileStarted] once. Submit forms with the `*Submitted` events;
/// the result appears in `ProfileLoaded.action`. A second submit while one is
/// running is ignored. Fields are validated locally first, so an invalid form
/// never reaches the repository.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required this._repository, required this._clock})
    : super(const ProfileLoading()) {
    on<ProfileStarted>(_onStarted);
    on<_ProfileAccountChanged>(_onAccountChanged);
    on<ProfileUpdateSubmitted>(_onUpdate);
    on<ProfileLicenceSubmitted>(_onLicence);
    on<ProfileLicenceRetried>(
      (event, emit) => _lastLicence == null
          ? null
          : _onLicence(ProfileLicenceSubmitted(_lastLicence!), emit),
    );
    on<ProfileIdentitySubmitted>(_onIdentity);
    on<ProfileIdentityRetried>(
      (event, emit) => _lastIdentity == null
          ? null
          : _onIdentity(ProfileIdentitySubmitted(_lastIdentity!), emit),
    );
    on<ProfilePayoutSubmitted>(_onPayout);
    on<ProfileActionAcknowledged>(_onAcknowledged);
  }

  final ProfileRepository _repository;
  final Clock _clock;

  LicenceSubmission? _lastLicence;
  IdentitySubmission? _lastIdentity;
  bool _watching = false;

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    final loaded = await _loadAll();
    if (loaded case Failure(:final failure)) {
      emit(ProfileFailure(failure));
      return;
    }
    emit((loaded as Success<ProfileLoaded>).value);
    // One watch for the bloc's lifetime: later starts only reload the data.
    if (_watching) return;
    _watching = true;
    // Keeps the name, photo and rating fresh until the bloc closes.
    await emit.onEach<Result<UserAccount>>(
      _repository.watchProfile(),
      onData: (result) => add(_ProfileAccountChanged(result)),
    );
  }

  Future<Result<ProfileLoaded>> _loadAll() async {
    final account = await _repository.getProfile();
    if (account case Failure(:final failure)) return Result.failure(failure);
    final user = (account as Success<UserAccount>).value;

    final contact = await _repository.getContact();
    if (contact case Failure(:final failure)) return Result.failure(failure);

    Licence? licence;
    OwnerIdentity? identity;
    PayoutMethod? payout;
    if (user.role == UserRole.renter) {
      final result = await _repository.getLicence();
      if (result case Failure(:final failure)) return Result.failure(failure);
      licence = (result as Success<Licence?>).value;
    } else {
      final identityResult = await _repository.getIdentity();
      if (identityResult case Failure(:final failure)) {
        return Result.failure(failure);
      }
      final payoutResult = await _repository.getPayout();
      if (payoutResult case Failure(:final failure)) {
        return Result.failure(failure);
      }
      identity = (identityResult as Success<OwnerIdentity?>).value;
      payout = (payoutResult as Success<PayoutMethod?>).value;
    }
    return Result.success(
      ProfileLoaded(
        account: user,
        contact: (contact as Success<Contact>).value,
        licence: licence,
        identity: identity,
        payout: payout,
      ),
    );
  }

  void _onAccountChanged(
    _ProfileAccountChanged event,
    Emitter<ProfileState> emit,
  ) {
    final current = state;
    if (current is! ProfileLoaded) return;
    // A failed refresh keeps the data already on screen.
    if (event.result case Success(:final value)) {
      emit(current.copyWith(account: value));
    }
  }

  Future<void> _onUpdate(
    ProfileUpdateSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    final problem = event.update.validate(now: _clock.now());
    await _submit<void>(
      emit,
      ProfileActionKind.updateProfile,
      problem: problem,
      run: () => _repository.updateProfile(event.update),
      onSaved: (current, _) async {
        final contact = await _repository.getContact();
        return contact is Success<Contact>
            ? current.copyWith(contact: contact.value)
            : current;
      },
    );
  }

  Future<void> _onLicence(
    ProfileLicenceSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    _lastLicence = event.submission;
    await _submit<Licence>(
      emit,
      ProfileActionKind.licence,
      problem: event.submission.validate(now: _clock.now()),
      run: () => _repository.saveLicence(event.submission),
      onSaved: (current, licence) async => current.copyWith(licence: licence),
    );
  }

  Future<void> _onIdentity(
    ProfileIdentitySubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    _lastIdentity = event.submission;
    await _submit<OwnerIdentity>(
      emit,
      ProfileActionKind.identity,
      problem: event.submission.validate(),
      run: () => _repository.replaceIdentity(event.submission),
      onSaved: (current, identity) async =>
          current.copyWith(identity: identity),
    );
  }

  Future<void> _onPayout(
    ProfilePayoutSubmitted event,
    Emitter<ProfileState> emit,
  ) async {
    await _submit<PayoutMethod>(
      emit,
      ProfileActionKind.payout,
      problem: Validators.momoNumber(event.momoNumber),
      run: () => _repository.savePayout(event.momoNumber),
      onSaved: (current, payout) async => current.copyWith(payout: payout),
    );
  }

  void _onAcknowledged(
    ProfileActionAcknowledged event,
    Emitter<ProfileState> emit,
  ) {
    final current = state;
    if (current is! ProfileLoaded || current.action.isSubmitting) return;
    emit(current.copyWith(action: ProfileAction.idle));
  }

  /// Shared submit flow: validate, mark submitting, run, then report.
  ///
  /// A [ValidationFailure] coming back from the repository means the document
  /// check rejected the input (fields were already validated here), so the
  /// licence and identity forms show it as [ProfileActionStatus.verificationFailed].
  Future<void> _submit<T>(
    Emitter<ProfileState> emit,
    ProfileActionKind kind, {
    required String? problem,
    required Future<Result<T>> Function() run,
    required Future<ProfileLoaded> Function(ProfileLoaded current, T value)
    onSaved,
  }) async {
    final current = state;
    if (current is! ProfileLoaded || current.action.isSubmitting) return;

    if (problem != null) {
      emit(
        current.copyWith(
          action: ProfileAction(
            kind: kind,
            status: ProfileActionStatus.invalid,
            message: problem,
          ),
        ),
      );
      return;
    }

    emit(
      current.copyWith(
        action: ProfileAction(
          kind: kind,
          status: ProfileActionStatus.submitting,
        ),
      ),
    );
    final result = await run();
    if (isClosed) return;

    switch (result) {
      case Success<T>(:final value):
        final saved = await onSaved(current, value);
        if (isClosed) return;
        emit(
          saved.copyWith(
            account: (state as ProfileLoaded).account,
            action: ProfileAction(
              kind: kind,
              status: ProfileActionStatus.success,
            ),
          ),
        );
      case Failure<T>(:final failure):
        final isDocumentCheck =
            failure is ValidationFailure &&
            (kind == ProfileActionKind.licence ||
                kind == ProfileActionKind.identity);
        emit(
          current.copyWith(
            account: (state as ProfileLoaded).account,
            action: ProfileAction(
              kind: kind,
              status: isDocumentCheck
                  ? ProfileActionStatus.verificationFailed
                  : failure is ValidationFailure
                  ? ProfileActionStatus.invalid
                  : ProfileActionStatus.failure,
              message: failure.message,
            ),
          ),
        );
    }
  }
}
