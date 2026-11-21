import '../../../../core/domain/entities/vehicle_document.dart';
import '../../../../core/domain/enums/document_kind.dart';

abstract final class DocumentRules {
  static const List<DocumentKind> requiredKinds = [
    DocumentKind.insurance,
    DocumentKind.medical,
  ];

  /// Whether a paper expiring on [expiry] is still valid at [now]. Compared by
  /// calendar day, so a paper is valid through its expiry day (the same rule
  /// search applies to `docsValidUntil`).
  static bool isValidOn(DateTime expiry, DateTime now) {
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final today = DateTime(now.year, now.month, now.day);
    return !expiryDay.isBefore(today);
  }

  static String? expiry(DateTime? value, {required DateTime now}) {
    if (value == null) return 'Choose the expiry date.';
    if (!isValidOn(value, now)) return 'This document has expired.';
    return null;
  }

  static List<DocumentKind> missingRequired(
    Iterable<VehicleDocument> documents,
  ) {
    final present = documents.map((document) => document.kind).toSet();
    return requiredKinds.where((kind) => !present.contains(kind)).toList();
  }

  static DateTime? docsValidUntil(Iterable<VehicleDocument> documents) {
    final expiries = <DateTime>[];
    for (final kind in requiredKinds) {
      final matches = documents.where((document) => document.kind == kind);
      if (matches.isEmpty) return null;
      expiries.add(matches.first.expiry);
    }
    return expiries.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  static String? plateMatches(String? documentPlate, String listingPlate) {
    final typed = _normalise(documentPlate);
    if (typed.isEmpty) return 'Enter the plate shown on the document.';
    if (typed != _normalise(listingPlate)) {
      return 'The plate on this document must match the listing.';
    }
    return null;
  }

  static String _normalise(String? plate) =>
      (plate ?? '').replaceAll(' ', '').toUpperCase();
}
