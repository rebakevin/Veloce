import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/firestore_fields.dart';
import '../../constants/firestore_paths.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/enums/party.dart';
import '../../domain/enums/transaction_status.dart';
import '../../domain/enums/transaction_type.dart';
import '../../domain/services/atomic_write.dart';
import '../../domain/services/clock.dart';
import '../../domain/services/ledger_writer.dart';
import '../models/ledger_entry_model.dart';

class FirestoreLedgerWriter implements LedgerWriter {
  const FirestoreLedgerWriter(this._clock);

  final Clock _clock;

  @override
  void record(
    AtomicWrite write, {
    required Booking booking,
    required TransactionType type,
    required int amount,
    required Party from,
    required Party to,
    String reference = '',
  }) {
    final id = write.newId(FirestorePaths.transactions);
    final entry = LedgerEntry(
      id: id,
      bookingId: booking.id,
      vehicleId: booking.vehicleId,
      ownerId: booking.ownerId,
      renterId: booking.renterId,
      type: type,
      amount: amount,
      fromParty: from,
      toParty: to,
      reference: reference,
      status: TransactionStatus.success,
      at: _clock.now(),
    );
    write.set(
      '${FirestorePaths.transactions}/$id',
      LedgerEntryModel.toMap(entry)
        ..[FirestoreFields.at] = FieldValue.serverTimestamp(),
    );
  }
}
