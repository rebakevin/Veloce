import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/domain/enums/vehicle_status.dart';

import 'document_rules.dart';

/// How document expiry affects a car's listing status.
abstract final class DocumentStatusRules {
  /// Required papers (insurance, medical) whose expiry has passed.
  static Set<DocumentKind> expiredRequired(
    Iterable<VehicleDocument> documents, {
    required DateTime now,
  }) {
    return {
      for (final document in documents)
        if (DocumentRules.requiredKinds.contains(document.kind) &&
            !document.expiry.isAfter(now))
          document.kind,
    };
  }

  /// The status to store after documents changed. An expired or missing
  /// required paper pauses the car; otherwise [current] is kept, so a car
  /// paused by expiry stays paused until the owner resumes it.
  static VehicleStatus statusAfter(
    Iterable<VehicleDocument> documents, {
    required VehicleStatus current,
    required DateTime now,
  }) {
    final validUntil = DocumentRules.docsValidUntil(documents);
    if (validUntil == null || !validUntil.isAfter(now)) {
      return VehicleStatus.paused;
    }
    return current;
  }
}
