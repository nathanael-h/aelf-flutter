/// The language the Bible text is shown in: the Bible reader, the Office of
/// Readings' biblical reading, and the Mass readings all share this choice.
/// French is always available; Greek (New Testament only, no Septuagint yet)
/// and Hebrew (proto-canonical Old Testament only) never both cover the same
/// book today.
enum BibleLanguage { french, greek, hebrew }

extension BibleLanguageCycle on BibleLanguage {
  BibleLanguage get next =>
      BibleLanguage.values[(index + 1) % BibleLanguage.values.length];
}
