/// Represents a section/tab in an office
enum OfficeSectionType {
  introduction,
  invitatory,
  hymns,
  psalmody,
  reading,
  biblicalReading,
  patristicReading,
  canticle,
  intercession,
  teDeum,
  oration,
  marialHymns,
}

/// Configuration for a single section in an office
class OfficeSection {
  final OfficeSectionType type;
  final String? label;
  final bool conditional;
  final dynamic data;

  const OfficeSection({
    required this.type,
    this.label,
    this.conditional = false,
    this.data,
  });

  // Factory constructors for common sections
  static OfficeSection introduction({String? label}) => OfficeSection(
        type: OfficeSectionType.introduction,
        label: label ?? 'Introduction',
      );

  static OfficeSection invitatory({String? label}) => OfficeSection(
        type: OfficeSectionType.invitatory,
        label: label ?? 'Invitatoire',
      );

  static OfficeSection hymns({String? label}) => OfficeSection(
        type: OfficeSectionType.hymns,
        label: label ?? 'Hymne',
      );

  static OfficeSection psalmody({int? count, String? label}) => OfficeSection(
        type: OfficeSectionType.psalmody,
        label: label,
        data: count,
      );

  static OfficeSection reading({String? label}) => OfficeSection(
        type: OfficeSectionType.reading,
        label: label ?? 'Lecture',
      );

  static OfficeSection biblicalReading({String? label}) => OfficeSection(
        type: OfficeSectionType.biblicalReading,
        label: label ?? 'Lecture biblique',
      );

  static OfficeSection patristicReading({String? label}) => OfficeSection(
        type: OfficeSectionType.patristicReading,
        label: label ?? 'Lecture patristique',
      );

  static OfficeSection canticle({
    required String canticleType,
    String? label,
  }) =>
      OfficeSection(
        type: OfficeSectionType.canticle,
        label: label ?? 'Cantique',
        data: canticleType,
      );

  static OfficeSection intercession({String? label}) => OfficeSection(
        type: OfficeSectionType.intercession,
        label: label ?? 'Intercession',
      );

  static OfficeSection teDeum({bool conditional = true, String? label}) =>
      OfficeSection(
        type: OfficeSectionType.teDeum,
        label: label ?? 'Te Deum',
        conditional: conditional,
      );

  static OfficeSection oration({String? label}) => OfficeSection(
        type: OfficeSectionType.oration,
        label: label ?? 'Oraison',
      );

  static OfficeSection marialHymns({String? label}) => OfficeSection(
        type: OfficeSectionType.marialHymns,
        label: label ?? 'Hymne mariale',
      );
}
