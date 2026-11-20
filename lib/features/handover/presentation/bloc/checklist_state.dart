import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/checklist_media.dart';

enum ChecklistSubmitStatus { idle, saving, submitted, failed }

class ChecklistState extends Equatable {
  const ChecklistState({
    this.media = const [],
    this.checkedItems = const {},
    this.isUploading = false,
    this.submitStatus = ChecklistSubmitStatus.idle,
    this.submitMessage,
    this.errorMessage,
  });

  final List<ChecklistMedia> media;
  final Set<String> checkedItems;
  final bool isUploading;
  final ChecklistSubmitStatus submitStatus;

  /// Text for the snackbar once a submit has finished or failed.
  final String? submitMessage;
  final String? errorMessage;

  bool get isSaving => submitStatus == ChecklistSubmitStatus.saving;

  bool get hasPhoto => media.any((item) => item.mediaType.key == 'photo');

  // At least one photo is required before confirmation.
  bool get canConfirm => hasPhoto && !isUploading && !isSaving;

  int get completedItems => checkedItems.length;

  ChecklistState copyWith({
    List<ChecklistMedia>? media,
    Set<String>? checkedItems,
    bool? isUploading,
    ChecklistSubmitStatus? submitStatus,
    String? submitMessage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChecklistState(
      media: media ?? this.media,
      checkedItems: checkedItems ?? this.checkedItems,
      isUploading: isUploading ?? this.isUploading,
      submitStatus: submitStatus ?? this.submitStatus,
      submitMessage: submitMessage ?? this.submitMessage,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    media,
    checkedItems,
    isUploading,
    submitStatus,
    submitMessage,
    errorMessage,
  ];
}
