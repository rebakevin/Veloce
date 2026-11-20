import 'package:flutter/material.dart';
import 'package:veloce/core/domain/entities/vehicle_document.dart';
import 'package:veloce/core/domain/enums/document_kind.dart';
import 'package:veloce/core/formatting/formatters.dart';
import 'package:veloce/core/theme/app_spacing.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/core/widgets/status_chip.dart';

import '../../domain/rules/document_rules.dart';

/// One paper of the car with its state and the action to add or replace it.
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    required this.kind,
    required this.document,
    required this.expired,
    required this.onEdit,
    super.key,
  });

  final DocumentKind kind;
  final VehicleDocument? document;
  final bool expired;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final current = document;
    final (label, tone) = switch ((current, expired)) {
      (null, _) => ('Not added', StatusTone.neutral),
      (_, true) => ('Expired', StatusTone.danger),
      _ => ('Valid', StatusTone.active),
    };
    final action = switch ((current, expired)) {
      (null, _) => 'Add',
      (_, true) => 'Replace',
      _ => 'Update',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(kind.label, style: AppTextStyles.cardTitle),
                ),
                StatusChip(label: label, tone: tone),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('Number: ${current.number}'),
              Text(
                '${expired ? 'Expired' : 'Expires'} '
                '${Formatters.date(current.expiry)}',
              ),
            ] else if (!DocumentRules.requiredKinds.contains(kind))
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm),
                child: Text('Optional. You can add it any time.'),
              ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onEdit,
                child: Text('$action ${kind.label.toLowerCase()}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
