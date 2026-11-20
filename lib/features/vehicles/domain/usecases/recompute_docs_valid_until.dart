import 'package:veloce/core/domain/entities/vehicle_document.dart';

import '../rules/document_rules.dart';

/// The earlier of the insurance and medical expiry, or null while either is
/// missing.
class RecomputeDocsValidUntil {
  const RecomputeDocsValidUntil();

  DateTime? call(Iterable<VehicleDocument> documents) =>
      DocumentRules.docsValidUntil(documents);
}
