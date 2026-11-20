import 'package:flutter/material.dart';

import 'package:veloce/core/domain/enums/booking_status.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/widgets/dialog_buttons.dart';

import '../../domain/entities/booking_view.dart';

/// Confirmation before cancelling. A paid booking states the full refund.
Future<bool> showCancelBookingDialog(
  BuildContext context,
  BookingView view,
) async {
  final paid = view.booking.status == BookingStatus.confirmed;
  final refund = paid
      ? 'Everything paid, ${Formatters.rwf(view.booking.totalPayable)}, is refunded in full. '
      : 'Nothing has been paid, so nothing is charged. ';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(paid ? 'Cancel this booking?' : 'Cancel this request?'),
      content: Text(
        'The other side is told. Either side can cancel until both hands have '
        'confirmed pickup. $refund The dates are released.',
      ),
      actions: [
        DialogButtons(
          confirmLabel: paid ? 'Cancel booking' : 'Cancel request',
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          destructive: true,
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
