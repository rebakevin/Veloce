import '../../../../core/domain/entities/vehicle_document.dart';
import '../../../../core/domain/enums/document_kind.dart';

abstract final class DocumentRules {
  static const List<DocumentKind> requiredKinds = [
    DocumentKind.insurance,
    DocumentKind.medical,
  ];

  static String? expiry(DateTime? value, {required DateTime now}) {
    if (value == null) return 'Choose the expiry date.';
    if (!value.isAfter(now)) return 'This document has expired.';
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
}
