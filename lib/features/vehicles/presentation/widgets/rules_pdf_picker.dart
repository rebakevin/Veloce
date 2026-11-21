import 'package:file_picker/file_picker.dart';

import '../../domain/entities/rules_pdf.dart';

/// Picks one PDF. A seam so screens can be tested without the platform plugin.
abstract interface class RulesPdfPicker {
  /// The picked PDF, or `null` when the user cancelled.
  Future<RulesPdf?> pick();
}

/// Picker through `file_picker`, limited to `.pdf` files.
class FilePickerRulesPdfPicker implements RulesPdfPicker {
  const FilePickerRulesPdfPicker();

  @override
  Future<RulesPdf?> pick() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [RulesPdf.extension],
    );
    if (files.isEmpty) return null;
    final file = files.first;
    return RulesPdf(bytes: await file.readAsBytes(), name: file.name);
  }
}
