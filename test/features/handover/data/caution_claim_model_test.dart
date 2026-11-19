import 'package:flutter_test/flutter_test.dart';
import 'package:veloce/core/data/models/caution_claim_model.dart';
import 'package:veloce/core/domain/entities/caution_claim.dart';
import 'package:veloce/core/domain/entities/claim_history_entry.dart';
import 'package:veloce/core/domain/enums/claim_response.dart';
import 'package:veloce/core/domain/enums/claim_status.dart';

void main() {
  group('CautionClaimModel', () {
    final date = DateTime(2026, 11, 19, 10, 30);

    final claim = CautionClaim(
      bookingId: 'booking_123',
      originalAmount: 50000,
      currentAmount: 40000,
      reason: 'Vehicle body damage',
      evidenceUrls: [
        'https://example.com/evidence1.jpg',
        'https://example.com/evidence2.jpg',
      ],
      renterResponse: ClaimResponse.disputed,
      history: [
        ClaimHistoryEntry(
          amount: 50000,
          reason: 'Initial damage claim',
          at: date,
          response: ClaimResponse.none,
        ),
        ClaimHistoryEntry(
          amount: 40000,
          reason: 'Revised damage claim',
          at: date,
          response: ClaimResponse.disputed,
        ),
      ],
      status: ClaimStatus.open,
      updatedAt: date,
    );

    test('converts a caution claim to Firestore data', () {
      final map = CautionClaimModel.toMap(claim);

      expect(map['originalAmount'], 50000);
      expect(map['currentAmount'], 40000);
      expect(map['reason'], 'Vehicle body damage');
      expect(map['evidenceUrls'], hasLength(2));
      expect(map['renterResponse'], 'disputed');
      expect(map['status'], 'open');
      expect(map['history'], hasLength(2));
    });

    test('converts Firestore data back to a caution claim', () {
      final map = CautionClaimModel.toMap(claim);

      final result = CautionClaimModel.fromMap('booking_123', map);

      expect(result.bookingId, 'booking_123');
      expect(result.originalAmount, 50000);
      expect(result.currentAmount, 40000);
      expect(result.reason, 'Vehicle body damage');
      expect(result.evidenceUrls, hasLength(2));
      expect(result.renterResponse, ClaimResponse.disputed);
      expect(result.status, ClaimStatus.open);
      expect(result.history, hasLength(2));
    });

    test('preserves claim history details', () {
      final map = CautionClaimModel.toMap(claim);

      final result = CautionClaimModel.fromMap('booking_123', map);

      expect(result.history.first.amount, 50000);
      expect(result.history.first.response, ClaimResponse.none);

      expect(result.history.last.amount, 40000);
      expect(result.history.last.response, ClaimResponse.disputed);
      expect(result.history.last.reason, 'Revised damage claim');
    });
  });
}
