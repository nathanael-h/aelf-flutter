import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  // Mappe liturgyType (interne) → slug URL aelf.org
  static const Map<String, String> _slugMap = {
    'messes': 'messe',
    'lectures': 'lectures',
    'laudes': 'laudes',
    'tierce': 'tierce',
    'sexte': 'sexte',
    'none': 'none',
    'vepres': 'vepres',
    'complies': 'complies',
    'offline_morning': 'laudes',
    'offline_readings': 'lectures',
    'offline_tierce': 'tierce',
    'offline_sexte': 'sexte',
    'offline_none': 'none',
    'offline_vespers': 'vepres',
    'offline_complines': 'complies',
  };

  // Régions valides sur aelf.org ; fallback sur 'romain' si valeur inconnue
  static const Set<String> _validRegions = {
    'afrique',
    'belgique',
    'canada',
    'france',
    'luxembourg',
    'romain',
    'suisse',
    'monaco',
  };

  static String _safeRegion(String region) =>
      _validRegions.contains(region) ? region : 'romain';

  static String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return DateFormat.yMMMMEEEEd('fr_FR').format(date);
  }

  /// Retourne le slug de l'office pour [liturgyType], ou null si pas partageable.
  static String? slugFor(String liturgyType) => _slugMap[liturgyType];

  /// Partage un office liturgique.
  static Future<void> shareLiturgy({
    required String title,
    required String liturgyType,
    required String date,
    required String region,
  }) async {
    final slug = _slugMap[liturgyType];
    if (slug == null) return;

    final safeRegion = _safeRegion(region);
    final url = 'http://www.aelf.org/$date/$safeRegion/$slug';
    final subject = '$title du ${_formatDate(date)}';

    // TODO(share): inclure l'ancre de l'onglet courant (#office_psaume1 etc.)
    // nécessite d'exposer l'index d'onglet dans LiturgyState.
    try {
      await SharePlus.instance.share(
        ShareParams(subject: subject, text: '$subject : $url'),
      );
    } catch (_) {
      // Share cancelled or failed silently.
    }
  }

  /// Partage un chapitre biblique.
  static Future<void> shareBible({
    required String formattedBookName,
    required String book,
    required String chapter,
  }) async {
    final url = 'https://www.aelf.org/bible/$book/$chapter';
    final subject = '$formattedBookName — Chapitre $chapter';
    try {
      await SharePlus.instance.share(
        ShareParams(subject: subject, text: '$subject : $url'),
      );
    } catch (_) {
      // Share cancelled or failed silently.
    }
  }
}
