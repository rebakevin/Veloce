import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/data/services/booking_lookup.dart';
import '../../../../core/domain/entities/booking.dart';
import '../../../../core/domain/entities/checklist_entry.dart';
import '../../../../core/domain/enums/booking_actor.dart';
import '../../../../core/domain/enums/booking_status.dart';
import '../../../../core/domain/enums/checklist_kind.dart';
import '../../../../core/domain/enums/checklist_side.dart';
import '../../../../core/domain/enums/media_type.dart';
import '../../../../core/domain/services/auth_session.dart';
import '../../../../core/domain/services/clock.dart';
import '../../../../core/domain/services/media_storage.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/handover_repository.dart';
import '../bloc/checklist_cubit.dart';
import '../bloc/checklist_state.dart';

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
          return Scaffold(
            appBar: AppBar(title: const Text('Checklist')),
            body: const Center(child: Text('Could not load this booking.')),
          );
        }

        return snapshot.data!.when(
          success: (booking) => _buildChecklist(context, booking),
          failure: (failure) => Scaffold(
            appBar: AppBar(title: const Text('Checklist')),
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
      return Scaffold(
        appBar: AppBar(title: const Text('Checklist')),
        body: const Center(
          child: Text('You do not have access to this booking.'),
        ),
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
        kind: kind,
        side: side,
        mediaStorage: GetIt.I<MediaStorage>(),
        clock: GetIt.I<Clock>(),
      ),
      child: _ChecklistContent(
        booking: booking,
        bookingId: bookingId,
        kind: kind,
        actor: actor,
        side: side,
      ),
    );
  }
}

class _ChecklistContent extends StatefulWidget {
  const _ChecklistContent({
    required this.booking,
    required this.bookingId,
    required this.kind,
    required this.actor,
    required this.side,
  });

  final Booking booking;
  final String bookingId;
  final ChecklistKind kind;
  final BookingActor actor;
  final ChecklistSide side;

  @override
  State<_ChecklistContent> createState() => _ChecklistContentState();
}

class _ChecklistContentState extends State<_ChecklistContent> {
  bool _isSaving = false;

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );

    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    final extension = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';

    await context.read<ChecklistCubit>().uploadMedia(
      bytes: bytes,
      extension: extension,
      mediaType: MediaType.photo,
    );
  }

  Future<void> _saveAndConfirm(ChecklistState state) async {
    if (_isSaving || !state.canConfirm) return;

    setState(() => _isSaving = true);

    final cubit = context.read<ChecklistCubit>();
    final repository = GetIt.I<HandoverRepository>();
    final clock = GetIt.I<Clock>();
    final userId = GetIt.I<AuthSession>().currentUserId!;

    final entries = cubit.checklistItems.map((item) {
      return ChecklistEntry(
        id: const Uuid().v4(),
        bookingId: widget.bookingId,
        kind: widget.kind,
        side: widget.side,
        item: item,
        ticked: state.checkedItems.contains(item),
        at: clock.now(),
      );
    }).toList();

    final saveResult = await repository.saveChecklist(
      bookingId: widget.bookingId,
      kind: widget.kind,
      side: widget.side,
      entries: entries,
      media: state.media,
    );

    if (!mounted) return;

    final saveSucceeded = saveResult.when(
      success: (_) => true,
      failure: (failure) {
        _showMessage(failure.message);
        return false;
      },
    );

    if (!saveSucceeded) {
      setState(() => _isSaving = false);
      return;
    }

    Result<Booking> confirmation;

    if (widget.kind == ChecklistKind.pickup) {
      confirmation = await repository.confirmPickup(
        bookingId: widget.bookingId,
        userId: userId,
        actor: widget.actor,
      );
    } else {
      if (widget.booking.status == BookingStatus.active) {
        final startResult = await repository.startReturn(
          bookingId: widget.bookingId,
          userId: userId,
          actor: widget.actor,
        );

        final started = startResult.when(
          success: (_) => true,
          failure: (failure) {
            _showMessage(failure.message);
            return false;
          },
        );

        if (!started) {
          if (mounted) setState(() => _isSaving = false);
          return;
        }
      }

      confirmation = await repository.confirmReturn(
        bookingId: widget.bookingId,
        userId: userId,
        actor: widget.actor,
      );
    }

    if (!mounted) return;

    confirmation.when(
      success: (_) {
        _showMessage(
          widget.kind == ChecklistKind.pickup
              ? 'Pickup checklist submitted.'
              : 'Return checklist submitted.',
        );
        context.pop();
      },
      failure: (failure) {
        _showMessage(failure.message);
        setState(() => _isSaving = false);
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isPickup = widget.kind == ChecklistKind.pickup;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPickup ? 'Pickup checklist' : 'Return checklist'),
      ),
      body: BlocBuilder<ChecklistCubit, ChecklistState>(
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
              Text(
                'Vehicle inspection',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...cubit.checklistItems.map(
                (item) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item),
                  value: state.checkedItems.contains(item),
                  onChanged: (_) => cubit.toggleItem(item),
                ),
              ),
              const Divider(height: 32),
              Text(
                'Vehicle photos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload at least one photo before submitting. '
                'You can remove photos before confirmation.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.isUploading || _isSaving ? null : _pickPhoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Add photo'),
              ),
              if (state.isUploading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                  leading: const Icon(Icons.image),
                  title: Text(media.mediaType.label),
                  subtitle: Text(
                    media.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove photo',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _isSaving
                        ? null
                        : () => cubit.removeMedia(media.id),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Completed inspection items: '
                '${state.completedItems}/${cubit.checklistItems.length}',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: state.canConfirm && !_isSaving
                    ? () => _saveAndConfirm(state)
                    : null,
                child: _isSaving
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
