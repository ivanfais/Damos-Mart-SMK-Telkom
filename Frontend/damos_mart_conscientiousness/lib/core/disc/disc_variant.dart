enum DiscVariant {
  influence,
  dominance,
  steadiness,
  conscientiousness;

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
        return 'Ramah, energik, dan suka berinteraksi.';
      case DiscVariant.dominance:
        return 'Tegas, fokus hasil, dan percaya diri.';
      case DiscVariant.steadiness:
        return 'Tenang, sabar, dan suportif.';
      case DiscVariant.conscientiousness:
        return 'Teliti, sistematis, dan analitis.';
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
