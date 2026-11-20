part of 'availability_bloc.dart';

sealed class AvailabilityState extends Equatable {
  const AvailabilityState();

  @override
  List<Object?> get props => [];
}

final class AvailabilityLoading extends AvailabilityState {
  const AvailabilityLoading();
}

final class AvailabilityFailure extends AvailabilityState {
  const AvailabilityFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class AvailabilityLoaded extends AvailabilityState {
  const AvailabilityLoaded({
    required this.overview,
    required this.from,
    required this.to,
    this.edited = false,
    this.saving = false,
    this.saved = false,
    this.notice,
  });

  final AvailabilityOverview overview;

  /// The range being edited; starts as the car's saved range.
  final DateTime? from;
  final DateTime? to;

  /// True once the owner changed the range, so a live update keeps it.
  final bool edited;
  final bool saving;

  /// True right after a successful save.
  final bool saved;

  /// Why the last save was refused or failed.
  final String? notice;

  /// Why the current range cannot be saved, or null.
  String? get problem => AvailabilityRules.check(
    from: from,
    to: to,
    bookedDays: overview.bookedDays,
  );

  AvailabilityLoaded copyWith({
    AvailabilityOverview? overview,
    DateTime? from,
    DateTime? to,
    bool? edited,
    bool? saving,
    bool? saved,
    String? notice,
    bool clearNotice = false,
  }) {
    return AvailabilityLoaded(
      overview: overview ?? this.overview,
      from: from ?? this.from,
      to: to ?? this.to,
      edited: edited ?? this.edited,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props => [
    overview,
    from,
    to,
    edited,
    saving,
    saved,
    notice,
  ];
}
