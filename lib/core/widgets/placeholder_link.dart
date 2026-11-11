/// A navigation the mock shows on a screen, kept on its placeholder so the flow
/// can be walked before the screen is built.
class PlaceholderLink {
  const PlaceholderLink(this.label, this.path, {this.isTab = false});

  final String label;
  final String path;

  /// Tab roots replace the stack (`go`); everything else opens on top (`push`).
  final bool isTab;
}
