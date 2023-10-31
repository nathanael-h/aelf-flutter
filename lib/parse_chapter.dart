/*
This file is derived from https://github.com/HackMyChurch/aelf-dailyreadings
MIT, 2013-2018 Jean-Tiare Le Bigot <jt@yadutaf.fr>
AGPL license does not apply to this file
*/


main() {
  //
  parse_reference("1,25-30");

}
parse_reference(String reference) {
    // Remove letters after the verses
    reference = reference.replaceAll(RegExp(r"/[a-z]*/g"),"");

    // Start the parsing
    var ranges = [];
    var state = 'chapter_start';
    var current = {};
    while (reference != "") {
        // Parse a chunk
        var match = (RegExp(r'^([0-9]+[A-Z]*)(.?)(.*)')).allMatches(reference);
        var number = match.first[1];
        var separator = match.first[2];
        reference = match.first[3] ?? "";

        switch (state) {
            // State: chapter_start
            case 'chapter_start':
                current = {
                    'chapter_start': number,
                    'verse_start': 0,
                    'chapter_end': number,
                    'verse_end': double.infinity
                };
                switch (separator) {
                    case "":
                        ranges.add(current);
                        current = {};
                        reference = "";
                        break;
                    case ",":
                        state = 'verse_start';
                        break;
                    case "-":
                        state = 'chapter_end';
                        break;
                    default:
                        print("Failed to parse reference: invalid separator '" + separator.toString() + "'");
                        reference = "";
                        break;
                }
                break;

                // State: verse_start
            case 'verse_start':
                current['verse_start'] = number;
                current['verse_end'] = current['verse_start'];
                switch (separator) {
                    case "":
                        ranges.add(current);
                        current = {
                            'chapter_start': current['chapter_end'],
                            'verse_start': 0,
                            'chapter_end': current['chapter_end'],
                            'verse_end': 0
                        };
                        reference = "";
                        break;
                    case ".":
                    case ",":
                        current['verse_end'] = current['verse_start'];
                        ranges.add(current);
                        current = {
                            'chapter_start': current['chapter_end'],
                            'verse_start': 0,
                            'chapter_end': current['chapter_end'],
                            'verse_end': 0
                        };
                        state = 'verse_start';
                        break;
                   case ";":
                       ranges.add(current);
                       current = {};
                       state = 'chapter_start';
                       break;
                    case "-":
                        state = 'verse_end';
                        break;
                    case "–":
                        current['verse_end'] = double.infinity;
                        state = 'chapter_end';
                        break;
                    default:
                        print("Failed to parse reference: invalid separator '" + separator.toString() + "'");
                        reference = "";
                        break;
                }
                break;

                // State: verse_end
            case 'verse_end':
                current['verse_end'] = number;
                switch (separator) {
                    case "":
                        ranges.add(current);
                        current = {};
                        reference = "";
                        break;
                    case ".":
                    case ",":
                        ranges.add(current);
                        current = {
                            'chapter_start': current['chapter_end'],
                            'verse_start': 0,
                            'chapter_end': current['chapter_end'],
                            'verse_end': 0
                        };
                        state = 'verse_start';
                        break;
                    case ";":
                        ranges.add(current);
                        current = {};
                        state = 'chapter_start';
                        break;
                    default:
                        print("Failed to parse reference: invalid separator '" + separator.toString() + "'");
                        reference = "";
                        break;
                }
                break;

                // State: chapter_end
            case 'chapter_end':
                current['chapter_end'] = number;
                current['verse_end'] = double.infinity;
                switch (separator) {
                    case "":
                        ranges.add(current);
                        current = {};
                        reference = "";
                        break;
                    case ",":
                        state = 'verse_end';
                        break;
                    case ".":
                        ranges.add(current);
                        current = {
                            'chapter_start': current['chapter_end'],
                            'verse_start': 0,
                            'chapter_end': current['chapter_end'],
                            'verse_end': 0
                        };
                        state = 'verse_start';
                        break;
                    case ";":
                        ranges.add(current);
                        current = {};
                        state = 'chapter_start';
                        break;
                    default:
                        print("Failed to parse reference: invalid separator '" + separator.toString() + "'");
                        reference = "";
                        break;
                }
                break;

                // Invalid state
            default:
                print("Failed to parse reference: invalid state '" + state + "'");
                reference = "";
                break;
        }
    }

    // All done
    print(ranges);
    return ranges;
}