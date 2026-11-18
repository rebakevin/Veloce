import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/checklist_media.dart';

class ChecklistState extends Equatable {
  const ChecklistState({
    this.media = const [],
    this.isUploading = false,
    this.errorMessage,
  });

  final List<ChecklistMedia> media;
  final bool isUploading;
  final String? errorMessage;

  bool get hasPhoto => media.any((item) => item.mediaType.key == 'photo');

  bool get canConfirm => hasPhoto && !isUploading;

  ChecklistState copyWith({
    List<ChecklistMedia>? media,
    bool? isUploading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChecklistState(
      media: media ?? this.media,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [media, isUploading, errorMessage];
}
