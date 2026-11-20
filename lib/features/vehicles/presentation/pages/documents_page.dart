import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:veloce/core/domain/entities/vehicle.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/widgets/app_messenger.dart';
import 'package:veloce/core/widgets/error_view.dart';
import 'package:veloce/core/widgets/loading_view.dart';
import 'package:veloce/core/widgets/page_app_bar.dart';
import 'package:veloce/core/widgets/photo_picker.dart';
import 'package:veloce/core/widgets/primary_button.dart';

import '../bloc/documents_bloc.dart';
import '../widgets/document_editor_sheet.dart';
import '../widgets/document_tile.dart';
import '../widgets/paused_by_expiry_banner.dart';

/// Papers of one car: add the yellow paper later, replace expired ones, and
/// resume a car that was paused by expiry.
class DocumentsPage extends StatelessWidget {
  const DocumentsPage({
    required this.vehicleId,
    super.key,
    this.picker = const ImagePickerPhotoPicker(),
  });

  final String vehicleId;
  final PhotoPicker picker;

  void _edit(
    BuildContext context,
    Vehicle vehicle,
    DocumentsLoaded state,
    DocumentKind kind,
  ) {
    final bloc = context.read<DocumentsBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: DocumentEditorSheet(
          kind: kind,
          vehicle: vehicle,
          existing: state.documentOf(kind),
          picker: picker,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PageAppBar(title: 'Car documents'),
      body: BlocConsumer<DocumentsBloc, DocumentsState>(
        listenWhen: (previous, current) =>
            current is DocumentsLoaded &&
            current.notice != null &&
            (previous is! DocumentsLoaded || previous.notice != current.notice),
        listener: (context, state) {
          final notice = (state as DocumentsLoaded).notice!;
          final messenger = GetIt.I<AppMessenger>();
          notice.isError
              ? messenger.error(notice.message)
              : messenger.success(notice.message);
        },
        builder: (context, state) => switch (state) {
          DocumentsLoading() => const LoadingView(),
          DocumentsFailure(:final message) => ErrorView(
            message: message,
            onRetry: () =>
                context.read<DocumentsBloc>().add(DocumentsStarted(vehicleId)),
          ),
          DocumentsLoaded() => _Documents(
            state: state,
            onEdit: (kind) => _edit(context, state.vehicle, state, kind),
          ),
        },
      ),
    );
  }
}

class _Documents extends StatelessWidget {
  const _Documents({required this.state, required this.onEdit});

  final DocumentsLoaded state;
  final ValueChanged<DocumentKind> onEdit;

  @override
  Widget build(BuildContext context) {
    final idle = state.busy == DocumentsBusy.none;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      children: [
        if (state.pausedByExpiry) ...[
          PausedByExpiryBanner(expired: state.expired),
          const SizedBox(height: AppSpacing.lg),
        ],
        for (final kind in DocumentKind.values)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: DocumentTile(
              kind: kind,
              document: state.documentOf(kind),
              expired: state.expired.contains(kind),
              onEdit: idle ? () => onEdit(kind) : null,
            ),
          ),
        if (state.canResume) ...[
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Resume listing',
            isLoading: state.busy == DocumentsBusy.resuming,
            onPressed: idle
                ? () => context.read<DocumentsBloc>().add(
                    const DocumentsResumeRequested(),
                  )
                : null,
          ),
        ],
      ],
    );
  }
}
