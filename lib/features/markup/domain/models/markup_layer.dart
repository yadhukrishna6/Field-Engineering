enum MarkupLayer {
  originalDrawing('Original drawing'),
  markups('Markups'),
  measurements('Measurements'),
  issues('Issues'),
  photos('Photos'),
  inspection('Inspection'),
  previousRevision('Previous revision');

  final String displayName;
  const MarkupLayer(this.displayName);

  static MarkupLayer fromString(String? name) {
    if (name == null) return MarkupLayer.markups;
    return MarkupLayer.values.firstWhere(
      (l) => l.name.toLowerCase() == name.toLowerCase() || l.displayName.toLowerCase() == name.toLowerCase(),
      orElse: () => MarkupLayer.markups,
    );
  }
}
