import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/data/services/booking_lookup.dart';
import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/enums/booking_actor.dart';
import '../../../../core/domain/enums/booking_status.dart';
import '../../../../core/domain/enums/checklist_kind.dart';
import '../../../../core/domain/enums/checklist_side.dart';
import '../../../../core/domain/enums/media_type.dart';
import '../../../../core/domain/services/auth_session.dart';
import '../../../../core/domain/services/clock.dart';
import '../../../../core/domain/services/media_storage.dart';
import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/page_app_bar.dart';
import '../../domain/repositories/handover_repository.dart';
import '../bloc/checklist_cubit.dart';
import '../bloc/checklist_state.dart';
import '../widgets/late_fee_preview_card.dart';

class ChecklistPage extends StatelessWidget {
  const ChecklistPage({required this.bookingId, required this.kind, super.key});

  final String bookingId;
  final ChecklistKind kind;

  @override
  Widget build(BuildContext context) {
    final lookup = GetIt.I<BookingLookup>();

    return StreamBuilder<Result<Booking>>(
      stream: lookup.watch(bookingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            appBar: PageAppBar(title: 'Checklist'),
            body: Center(child: Text('Could not load this booking.')),
          );
        }

        return snapshot.data!.when(
          success: (booking) => _buildChecklist(context, booking),
          failure: (failure) => Scaffold(
            appBar: const PageAppBar(title: 'Checklist'),
            body: Center(child: Text(failure.message)),
          ),
        );
      },
    );
  }

  Widget _buildChecklist(BuildContext context, Booking booking) {
    final userId = GetIt.I<AuthSession>().currentUserId;

    if (userId == null ||
        (userId != booking.ownerId && userId != booking.renterId)) {
      return const Scaffold(
        appBar: PageAppBar(title: 'Checklist'),
        body: Center(child: Text('You do not have access to this booking.')),
      );
    }

    final actor = userId == booking.ownerId
        ? BookingActor.owner
        : BookingActor.renter;

    final side = actor == BookingActor.owner
        ? ChecklistSide.owner
        : ChecklistSide.renter;

    return BlocProvider(
      create: (_) => ChecklistCubit(
        bookingId: bookingId,
        userId: userId,
        kind: kind,
        actor: actor,
        side: side,
        startReturnFirst:
            kind == ChecklistKind.returning &&
            booking.status == BookingStatus.active,
        mediaStorage: GetIt.I<MediaStorage>(),
        repository: GetIt.I<HandoverRepository>(),
        clock: GetIt.I<Clock>(),
      )..load(),
      child: _ChecklistContent(kind: kind, booking: booking),
    );
  }
}

class _ChecklistContent extends StatelessWidget {
  const _ChecklistContent({required this.kind, required this.booking});

  final ChecklistKind kind;
  final Booking booking;

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    final cubit = context.read<ChecklistCubit>();

    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );

    await _upload(cubit, file, MediaType.photo, 'jpg');
  }

  Future<void> _recordVideo(BuildContext context) async {
    final cubit = context.read<ChecklistCubit>();

    final file = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(seconds: 30),
    );

    await _upload(cubit, file, MediaType.video, 'mp4');
  }

  Future<void> _upload(
    ChecklistCubit cubit,
    XFile? file,
    MediaType mediaType,
    String fallbackExtension,
  ) async {
    if (file == null || cubit.isClosed) return;

    final bytes = await file.readAsBytes();
    if (cubit.isClosed) return;

    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : fallbackExtension;

    await cubit.uploadMedia(
      bytes: bytes,
      extension: extension,
      mediaType: mediaType,
    );
  }

  void _onSubmitStatus(BuildContext context, ChecklistState state) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(state.submitMessage ?? '')));

    if (state.submitStatus == ChecklistSubmitStatus.submitted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = kind == ChecklistKind.pickup;

    return Scaffold(
      appBar: PageAppBar(
        title: isPickup ? 'Pickup checklist' : 'Return checklist',
      ),
      body: BlocConsumer<ChecklistCubit, ChecklistState>(
        listenWhen: (previous, current) =>
            previous.submitStatus != current.submitStatus &&
            (current.submitStatus == ChecklistSubmitStatus.submitted ||
                current.submitStatus == ChecklistSubmitStatus.failed),
        listener: _onSubmitStatus,
        builder: (context, state) {
          final cubit = context.read<ChecklistCubit>();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                isPickup
                    ? 'Inspect the vehicle before the rental begins.'
                    : 'Inspect the vehicle and record its condition at return.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              if (!isPickup) ...[
                LateFeePreviewCard(
                  booking: booking,
                  now: GetIt.I<Clock>().now(),
                ),
                const SizedBox(height: 16),
              ],
              _SectionCard(
                title: 'Vehicle inspection',
                children: [
                  ...cubit.checklistItems.map(
                    (item) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item),
                      value: state.checkedItems.contains(item),
                      onChanged: (_) => cubit.toggleItem(item),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Vehicle photos',
                children: [
                  const Text(
                    'Upload at least one photo before submitting. '
                    'You can remove photos before confirmation.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: state.isUploading || state.isSaving
                            ? null
                            : () => _pickPhoto(context, ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Take photo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: state.isUploading || state.isSaving
                            ? null
                            : () => _pickPhoto(context, ImageSource.gallery),
                        icon: const Icon(Icons.add_a_photo),
                        label: const Text('Choose photo'),
                      ),
                      OutlinedButton.icon(
                        onPressed: state.isUploading || state.isSaving
                            ? null
                            : () => _recordVideo(context),
                        icon: const Icon(Icons.videocam),
                        label: const Text('Record video (optional)'),
                      ),
                    ],
                  ),
                  if (state.isUploading) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: cubit.retryUpload,
                      child: const Text('Retry upload'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ...state.media.map(
                    (media) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        media.mediaType == MediaType.video
                            ? Icons.videocam
                            : Icons.image,
                      ),
                      title: Text(media.mediaType.label),
                      subtitle: Text(
                        media.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove media',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: state.isSaving
                            ? null
                            : () => cubit.removeMedia(media.id),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Completed inspection items: '
                '${state.completedItems}/${cubit.checklistItems.length}',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.canConfirm ? cubit.submit : null,
                child: state.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isPickup
                            ? 'Submit pickup checklist'
                            : 'Submit return checklist',
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}
