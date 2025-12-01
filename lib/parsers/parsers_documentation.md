# Liturgical Text Parsers - Architecture Documentation

## Overview

This documentation explains the architecture of the liturgical text parsing system used in the application. The system is designed to parse HTML content from liturgical texts (psalms, readings, prayers) and render them with proper formatting, including special liturgical symbols, verse numbers, and various text styles.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
│  (Morning View, Compline View, Scripture Widget, etc.)      │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ├─────────────────────┬──────────────────────┐
                 │                     │                      │
                 ▼                     ▼                      ▼
    ┌────────────────────┐  ┌──────────────────┐  ┌─────────────────┐
    │ FormattedTextParser│  │   PsalmParser    │  │  Widget Layer   │
    │  (Base Parser)     │  │ (Extended Parser)│  │                 │
    └────────────────────┘  └──────────────────┘  └─────────────────┘
             │                       │                      │
             │                       │                      │
             ▼                       ▼                      ▼
    ┌────────────────────┐  ┌──────────────────┐  ┌─────────────────┐
    │FormattedTextWidget │  │   PsalmWidget    │  │  AntiphonWidget │
    │   (No verse #s)    │  │  (With verse #s) │  │ ScriptureWidget │
    └────────────────────┘  └──────────────────┘  └─────────────────┘
```

## File Structure

```
lib/
├── parsers/
│   ├── formatted_text_parser.dart    # Base parser for formatted text
│   └── psalm_parser.dart              # Extended parser for psalms with verse numbers
└── widgets/
    ├── offline_liturgy_antiphon_display.dart
    ├── offline_liturgy_scripture_display.dart
    ├── offline_liturgy_psalms_display.dart
    ├── offline_liturgy_morning_view.dart
    └── offline_liturgy_compline_view.dart
```

## 1. FormattedTextParser (Base Parser)

### Purpose
Parses HTML content and renders formatted text **without verse numbers**. This is the foundational parser used for general liturgical texts.

### File
`lib/parsers/formatted_text_parser.dart`

### Key Classes

#### `TextConfig`
Configuration constants for text formatting:
```dart
class TextConfig {
  static const Color redColor = Colors.red;
  static const double paragraphSpacing = 16.0;
  static const double lineSpacing = 1.3;
  static const double textSize = 16.0;
  static const double superscriptOffset = -2.0;
  static const double superscriptScale = 0.7;
  static const double spaceIndentation = 20.0;
}
```

#### `TextSegment`
Represents a segment of text with formatting attributes:
```dart
class TextSegment {
  final String text;
  final bool isUnderlined;
  final bool isItalic;
  final String? className;  // For special classes like "espace", "droite"
}
```

#### `TextLine`
Represents a single line of text composed of multiple segments:
```dart
class TextLine {
  final List<TextSegment> segments;
}
```

#### `TextParagraph`
Represents a paragraph composed of multiple lines:
```dart
class TextParagraph {
  final List<TextLine> lines;
}
```

#### `FormattedTextParser`
Static parser that converts HTML to structured data:
```dart
static List<TextParagraph> parseHtml(String htmlContent)
```

#### `FormattedTextWidget`
Widget that renders the parsed data:
```dart
class FormattedTextWidget extends StatelessWidget {
  final List<TextParagraph> paragraphs;
  final TextStyle? textStyle;
  final double paragraphSpacing;
  final TextAlign textAlign;
}
```

### Supported HTML Features

1. **Text Formatting**
   - `<u>` - Underlined text
   - `<i>` and `<em>` - Italic text
   - `<br>` - Line breaks

2. **Special Classes**
   - `<span class="espace">` - Adds left indentation (20px)
   - `<span class="droite">` - Right-aligned text

3. **Liturgical Symbols**
   - `R/` → `℟` (Response symbol) - displayed in red
   - `V/` → `℣` (Verse symbol) - displayed in red
   - `+` and `*` - Displayed as red superscript

4. **Typography**
   - `'` (straight apostrophe) → `'` (typographic apostrophe)
   - `&nbsp;` → non-breaking space

### Usage Example

```dart
import 'package:aelf_flutter/parsers/formatted_text_parser.dart';

// Parse HTML content
String htmlContent = '<p>This is <u>underlined</u> text with R/ symbol.</p>';
final paragraphs = FormattedTextParser.parseHtml(htmlContent);

// Display with widget
FormattedTextWidget(
  paragraphs: paragraphs,
  textStyle: TextStyle(fontSize: 16.0, height: 1.3),
  textAlign: TextAlign.justify,
)
```

## 2. PsalmParser (Extended Parser)

### Purpose
Extends the base parser to handle **psalms with verse numbers**. Inherits all formatting capabilities from `FormattedTextParser` and adds verse number management.

### File
`lib/parsers/psalm_parser.dart`

### Key Classes

#### `PsalmConfig extends TextConfig`
Extends base configuration with psalm-specific settings:
```dart
class PsalmConfig extends TextConfig {
  // Psalm-specific
  static const double verseNumberSpacing = 4.0;
  static const double verseNumberSize = 10.0;
  static const double verseNumberWidth = 30.0;
  static const FontWeight verseNumberWeight = FontWeight.bold;
  
  // Re-exposes parent constants for convenience
  static const double paragraphSpacing = TextConfig.paragraphSpacing;
  // ... other re-exposed constants
}
```

#### `Verse`
Represents a verse with its number and lines (reuses `TextLine` from base parser):
```dart
class Verse {
  final int number;
  final List<TextLine> lines;  // Reuses TextLine from formatted_text_parser
}
```

#### `PsalmParagraph`
Represents a paragraph containing verses:
```dart
class PsalmParagraph {
  final List<Verse> verses;
}
```

#### `PsalmParser`
Static parser that converts HTML to psalm structure:
```dart
static List<PsalmParagraph> parseHtml(String htmlContent)
```

**Key difference from `FormattedTextParser`:**
- Recognizes `<span class="verse_number">X</span>` tags
- Groups text by verse numbers
- Creates `Verse` objects instead of plain lines

#### `PsalmWidget`
Widget that renders psalms with verse numbers in a left column:
```dart
class PsalmWidget extends StatelessWidget {
  final List<PsalmParagraph> paragraphs;
  final TextStyle? verseStyle;
  final TextStyle? numberStyle;
  final double paragraphSpacing;
  final double numberSpacing;
}
```

### Visual Layout

```
┌────────────────────────────────────────┐
│  [Verse #]  First line of verse text  │
│             Second line continues here │
│             Third line continues here  │
│                                        │
│  [Verse #]  Next verse starts here    │
│             And continues on next line │
└────────────────────────────────────────┘
    ↑           ↑
    30px wide   Text flows with proper
    Red, 10px   alignment and wrapping
    Slightly
    raised
```

### Supported HTML Features

All features from `FormattedTextParser` PLUS:

5. **Verse Numbers**
   - `<span class="verse_number">1</span>` - Verse number
   - Displayed in red, smaller size (10px)
   - Positioned in left column (30px wide)
   - Slightly raised (offset: -2px)

### Usage Example

```dart
import 'package:aelf_flutter/parsers/psalm_parser.dart';

// Parse psalm HTML with verse numbers
String psalmHtml = '''
<p>
  <span class="verse_number">1</span> 
  Blessed is the man<br>
  who walks not in the counsel of the wicked
</p>
''';

final paragraphs = PsalmParser.parseHtml(psalmHtml);

// Display with widget
PsalmWidget(
  paragraphs: paragraphs,
  verseStyle: TextStyle(fontSize: 16.0, height: 1.3),
  numberStyle: TextStyle(fontSize: 10.0, color: Colors.red),
)
```

## 3. Widget Integration

### AntiphonWidget
Uses `FormattedTextParser` (no verse numbers needed).

**Structure:**
```
[Ant. 1]  Text of the antiphon flows here
          and continues on multiple lines
```

**File:** `offline_liturgy_antiphon_display.dart`

```dart
class AntiphonWidget extends StatelessWidget {
  Widget _buildAntiphon(String antiphon, ...) {
    final paragraphs = FormattedTextParser.parseHtml(htmlContent);
    
    return Row(
      children: [
        SizedBox(width: 60.0, child: Text(label)),  // "Ant.", "Ant. 1", etc.
        Expanded(
          child: FormattedTextWidget(
            paragraphs: paragraphs,
            textStyle: TextStyle(fontSize: 13.0),
          ),
        ),
      ],
    );
  }
}
```

### ScriptureWidget
Uses `FormattedTextParser` with justified text alignment.

**File:** `offline_liturgy_scripture_display.dart`

```dart
class ScriptureWidget extends StatelessWidget {
  Widget _buildContent() {
    final paragraphs = FormattedTextParser.parseHtml(htmlContent);
    
    return FormattedTextWidget(
      paragraphs: paragraphs,
      textStyle: TextStyle(fontSize: 16.0, height: 1.3),
      textAlign: TextAlign.justify,  // Justified text for readings
    );
  }
}
```

### PsalmDisplayWidget
Uses `PsalmFromHtml` convenience widget from `psalm_parser.dart`.

**File:** `offline_liturgy_psalms_display.dart`

```dart
class PsalmDisplayWidget extends StatelessWidget {
  List<Widget> _buildPsalmContent(dynamic psalm) {
    return [
      LiturgyPartContentTitle(psalm.getTitle),
      if (_hasAntiphon) _buildAntiphon(),
      PsalmFromHtml(htmlContent: psalm.getContent),  // Uses PsalmParser internally
      if (_hasAntiphon) _buildAntiphon(),
    ];
  }
}
```

### Morning/Compline Views
Use `FormattedTextParser` for various text elements.

**Files:** `offline_liturgy_morning_view.dart`, `offline_liturgy_compline_view.dart`

```dart
Widget _buildFormattedText(String? content) {
  String htmlContent = content ?? '';
  if (!htmlContent.trim().startsWith('<p>')) {
    htmlContent = '<p>$htmlContent</p>';
  }
  
  final paragraphs = FormattedTextParser.parseHtml(htmlContent);
  
  return FormattedTextWidget(
    paragraphs: paragraphs,
    textStyle: TextStyle(fontSize: 16.0, height: 1.3),
  );
}
```

Used for:
- `officeIntroduction`
- `responsory`
- `oration`
- `morningConclusion` / `complineConclusion`

## Parser Flow Diagram

### FormattedTextParser Flow
```
HTML Input
    ↓
Parse <p> elements
    ↓
For each <p>:
    ├─ Process nodes recursively
    │   ├─ Skip <span class="verse_number">
    │   ├─ Handle <br> → new line
    │   ├─ Handle <u> → underlined flag
    │   ├─ Handle <em>/<i> → italic flag
    │   ├─ Handle <span class="X"> → className
    │   └─ Text nodes → TextSegment
    ↓
Group segments into TextLine
    ↓
Group lines into TextParagraph
    ↓
Return List<TextParagraph>
```

### PsalmParser Flow
```
HTML Input
    ↓
Parse <p> elements
    ↓
For each <p>:
    ├─ Process nodes recursively
    │   ├─ Handle <span class="verse_number"> → new verse
    │   ├─ Handle <br> → new line within verse
    │   ├─ Handle <u> → underlined flag
    │   ├─ Handle <em>/<i> → italic flag
    │   ├─ Handle <span class="X"> → className
    │   └─ Text nodes → TextSegment
    ↓
Group segments into TextLine (reused from base)
    ↓
Group lines into Verse (with number)
    ↓
Group verses into PsalmParagraph
    ↓
Return List<PsalmParagraph>
```

## Rendering Pipeline

### FormattedTextWidget Rendering
```
List<TextParagraph>
    ↓
For each paragraph:
    ├─ Wrap in Padding (paragraph spacing)
    │
    └─ For each line:
        ├─ Build InlineSpan list
        │   ├─ Process each segment
        │   │   ├─ Apply underline/italic
        │   │   ├─ Handle special characters (+, *, ℟, ℣)
        │   │   └─ Replace apostrophes
        │   │
        │   └─ Create TextSpan or WidgetSpan
        │
        ├─ Apply text alignment (left/right/justify)
        ├─ Apply indentation (if "espace" class)
        └─ Render as Text.rich
```

### PsalmWidget Rendering
```
List<PsalmParagraph>
    ↓
For each paragraph:
    ├─ Wrap in Padding (paragraph spacing)
    │
    └─ For each verse:
        └─ For each line in verse:
            ├─ Create Row:
            │   ├─ [First line only] Verse number column (30px)
            │   │   └─ Red, 10px, offset -2px, right-aligned
            │   │
            │   ├─ [Other lines] Left padding (30px + spacing)
            │   │
            │   └─ Expanded: Line text
            │       ├─ Build InlineSpan list (same as FormattedTextWidget)
            │       ├─ Apply text alignment
            │       ├─ Apply indentation (if "espace" class)
            │       └─ Render as Text.rich
```

## Configuration & Customization

### Text Styles
All text sizes and spacing can be customized in `TextConfig`:
```dart
class TextConfig {
  static const double textSize = 16.0;         // Main text size
  static const double lineSpacing = 1.3;        // Line height multiplier
  static const double paragraphSpacing = 16.0; // Space between paragraphs
  static const Color redColor = Colors.red;    // Special symbols color
}
```

### Psalm-Specific Styles
Additional psalm formatting in `PsalmConfig`:
```dart
class PsalmConfig extends TextConfig {
  static const double verseNumberSize = 10.0;     // Verse number font size
  static const double verseNumberWidth = 30.0;    // Width of number column
  static const double verseNumberSpacing = 4.0;   // Space between number and text
  static const double superscriptOffset = -2.0;   // Vertical offset for numbers
}
```

## Best Practices

### 1. When to Use FormattedTextParser
- Antiphons
- Scripture readings
- Prayers (orations)
- Introductions
- Responsories
- Conclusions
- Any text without verse numbers

### 2. When to Use PsalmParser
- Psalms
- Canticles
- Any text with verse numbers (`<span class="verse_number">`)

### 3. HTML Preparation
Always wrap content in `<p>` tags:
```dart
String htmlContent = content;
if (!htmlContent.trim().startsWith('<p>')) {
  htmlContent = '<p>$htmlContent</p>';
}
```

### 4. Error Handling
Check for null/empty content:
```dart
Widget _buildFormattedText(String? content) {
  if (content == null || content.isEmpty) {
    return const SizedBox.shrink();
  }
  // ... parse and render
}
```

## Common HTML Patterns

### Basic Text with Formatting
```html
<p>This is <u>underlined</u> and this is <em>italic</em> text.</p>
```

### Liturgical Symbols
```html
<p>R/ The Lord be with you.<br>
V/ And with your spirit.</p>
```
Renders as:
```
℟ The Lord be with you.
℣ And with your spirit.
```

### Special Characters
```html
<p>Glory to the Father, + and to the Son, * and to the Holy Spirit.</p>
```
The `+` and `*` appear as red superscript.

### Indentation
```html
<p><span class="espace">This text is indented 20px from the left.</span></p>
```

### Right Alignment
```html
<p><span class="droite">This text is right-aligned.</span></p>
```

### Psalm with Verse Numbers
```html
<p>
  <span class="verse_number">1</span> Blessed is the man<br>
  who walks not in the counsel of the wicked,<br>
  <span class="verse_number">2</span> but his delight is in the law of the LORD,<br>
  and on his law he meditates day and night.
</p>
```

## Summary

The parser system provides a clean, modular architecture:

1. **FormattedTextParser** - Base parser for general formatted text
2. **PsalmParser** - Extended parser for texts with verse numbers
3. **Separation of Concerns** - Parsing logic separated from rendering logic
4. **Reusability** - Shared `TextSegment` and `TextLine` classes
5. **Flexibility** - Easy to customize via config classes
6. **Maintainability** - Clear file structure and well-defined responsibilities

This architecture allows the application to handle diverse liturgical texts with consistent formatting while maintaining code clarity and ease of maintenance.