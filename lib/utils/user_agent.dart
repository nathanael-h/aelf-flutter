/// Helpers for the User-Agent sent to the AELF API.
library;

/// The OS version string for a Linux host, from `/etc/os-release` fields.
///
/// [buildId] is `BUILD_ID`, which rolling distributions (Arch) set and
/// point-release ones (Debian, Ubuntu, Fedora) do not — and those are exactly
/// what this repo's `debian/` and `snap/` packaging targets. Falls back to
/// `VERSION_ID`, then to the id alone, rather than dereferencing null.
String linuxOsVersion(String id, String? buildId, String? versionId) {
  final version = _firstNonEmpty([buildId, versionId]);
  return version == null ? id : '$id $version';
}

String? _firstNonEmpty(List<String?> candidates) {
  for (final candidate in candidates) {
    if (candidate != null && candidate.trim().isNotEmpty) return candidate;
  }
  return null;
}
