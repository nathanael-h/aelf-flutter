import 'package:flutter/material.dart';
import 'package:aelf_flutter/utils/bible_reference_fetcher.dart';

/// A tappable biblical reference shown as a book icon + reference label.
///
/// Tapping opens the reference in the Bible via [refButtonPressed]. Used as the
/// `trailing` widget of office section titles (psalms, canticle, scripture,
/// readings). [zoom] is the current `CurrentZoom` value (100 = 100%); callers
/// already have it from the title's trailing builder, so it is passed in
/// rather than read from a Consumer here.
class BiblicalReferenceButton extends StatelessWidget {
  final String reference;
  final double zoom;

  const BiblicalReferenceButton({
    super.key,
    required this.reference,
    this.zoom = 100,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return TextButton.icon(
      onPressed: () => refButtonPressed(reference, context),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(Icons.menu_book, size: 13 * zoom / 100, color: color),
      label: Text(
        reference,
        style: TextStyle(
          fontStyle: FontStyle.italic,
          fontSize: 12 * zoom / 100,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
