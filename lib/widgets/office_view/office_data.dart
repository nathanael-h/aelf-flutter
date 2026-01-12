import 'package:offline_liturgy/classes/office_elements_class.dart';

/// Base interface for all office types (Readings, Morning, Compline, Vespers, etc.)
/// Provides a unified way to access common properties across different office types
abstract class OfficeData {
  /// Celebration information (title, precedence, color, etc.)
  Celebration? get celebration;

  /// List of hymn codes/references
  List<String>? get hymns;

  /// Psalmody entries (psalms with their antiphons)
  List<PsalmEntry>? get psalmody;

  /// Oration texts
  List<String>? get oration;

  /// Whether this office is empty (no content)
  bool isEmpty();
}

/// Extension to make Readings implement OfficeData interface
/// This avoids modifying the offline_liturgy package
extension ReadingsAsOfficeData on dynamic {
  bool get isReadingsType => runtimeType.toString() == 'Readings';
  bool get isMorningType => runtimeType.toString() == 'Morning';
  bool get isComplineType => runtimeType.toString() == 'Compline';
}
