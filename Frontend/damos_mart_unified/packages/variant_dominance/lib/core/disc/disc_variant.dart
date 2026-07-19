enum DiscVariant {
  influence,
  dominance,
  steadiness,
  conscientiousness;

  static const List<DiscVariant> pickerOrder = [
    DiscVariant.dominance,
    DiscVariant.influence,
    DiscVariant.steadiness,
    DiscVariant.conscientiousness,
  ];

  String get label {
    switch (this) {
      case DiscVariant.influence:
        return 'Influence';
      case DiscVariant.dominance:
        return 'Dominance';
      case DiscVariant.steadiness:
        return 'Steadiness';
      case DiscVariant.conscientiousness:
        return 'Conscientiousness';
    }
  }

  String get description {
    switch (this) {
      case DiscVariant.influence:
        return 'Interaktif, penuh warna, dan ekspresif.';
      case DiscVariant.dominance:
        return 'Sederhana, cepat, dan efisien.';
      case DiscVariant.steadiness:
        return 'Sederhana, konsisten, dan nyaman digunakan.';
      case DiscVariant.conscientiousness:
        return 'Terstruktur, informatif, dan mudah dipahami.';
    }
  }

  String get apiValue {
    switch (this) {
      case DiscVariant.influence:
        return 'INFLUENCE';
      case DiscVariant.dominance:
        return 'DOMINANCE';
      case DiscVariant.steadiness:
        return 'STEADINESS';
      case DiscVariant.conscientiousness:
        return 'CONSCIENTIOUSNESS';
    }
  }

  static DiscVariant? fromStored(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final variant in DiscVariant.values) {
      if (variant.name == value) return variant;
    }
    return null;
  }
}
