import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/checklist_media.dart';

class ChecklistState extends Equatable {
  const ChecklistState({
    this.media = const [],
    this.checkedItems = const {},
    this.isUploading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<ChecklistMedia> media;
  final Set<String> checkedItems;
  final bool isUploading;
  final bool isSaving;
  final String? errorMessage;

  bool get hasPhoto => media.any((item) => item.mediaType.key == 'photo');

  // At least one photo is required before confirmation.
  bool get canConfirm => hasPhoto && !isUploading && !isSaving;

  int get completedItems => checkedItems.length;

  ChecklistState copyWith({
    List<ChecklistMedia>? media,
    Set<String>? checkedItems,
    bool? isUploading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChecklistState(
      media: media ?? this.media,
      checkedItems: checkedItems ?? this.checkedItems,
      isUploading: isUploading ?? this.isUploading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    media,
    checkedItems,
    isUploading,
    isSaving,
    errorMessage,
  ];
}
