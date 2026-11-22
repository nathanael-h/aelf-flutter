import 'package:aelf_flutter/states/featureFlagsState.dart';
import 'package:aelf_flutter/utils/geolocalisation_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Warns when offline geolocation is enabled but the system no longer
/// allows it — revoked after being granted. [GeolocalisationService
/// .detectAndPropose]'s hourly background check stays silent on purpose,
/// and the settings screen is only seen by someone who opens it, so this is
/// what actually surfaces the problem instead of leaving the user wondering
/// why detection stopped working.
///
/// Renders nothing itself; it only shows/hides a [MaterialBanner] through
/// the ambient [ScaffoldMessenger], so it must sit under a [Scaffold].
class GeolocationAccessBanner extends StatefulWidget {
  const GeolocationAccessBanner({super.key});

  @override
  State<GeolocationAccessBanner> createState() =>
      _GeolocationAccessBannerState();
}

class _GeolocationAccessBannerState extends State<GeolocationAccessBanner>
    with WidgetsBindingObserver {
  bool? _lastEnabled;

  /// What the banner currently up is warning about, null when none is.
  /// [ScaffoldMessengerState.showMaterialBanner] *queues*, so without this
  /// every resume while the permission stays revoked would stack another
  /// identical banner and the user would have to tap "Fermer" once per
  /// resume, each tap revealing the next copy.
  GeolocationAccess? _warnedAccess;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The settings toggle can learn of a new access state (e.g. a "don't ask
    // again" on a re-prompt) without the app ever being backgrounded —
    // refresh right away rather than waiting for the next resume.
    GeolocalisationService.accessChanged.addListener(_check);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GeolocalisationService.accessChanged.removeListener(_check);
    super.dispose();
  }

  // Back from the system settings, or from re-granting the permission
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  bool _effectivelyEnabled(FeatureFlagsState flags) =>
      flags.offlineGeolocationEnabled && flags.offlineLiturgyEnabled;

  void _clearWarning(ScaffoldMessengerState messenger) {
    messenger.clearMaterialBanners();
    _warnedAccess = null;
  }

  Future<void> _check() async {
    if (!mounted) return;
    final enabled = _effectivelyEnabled(context.read<FeatureFlagsState>());
    final messenger = ScaffoldMessenger.of(context);
    if (!enabled) {
      _clearWarning(messenger);
      return;
    }
    final access = await GeolocalisationService.access();
    if (!mounted) return;
    if (access == GeolocationAccess.allowed) {
      _clearWarning(messenger);
      return;
    }
    // Already warning about exactly this: leave the banner the user may
    // have dismissed alone until the situation actually changes.
    if (access == _warnedAccess) return;
    // Clear first, so a change of reason replaces the banner up rather
    // than queueing behind it.
    _clearWarning(messenger);
    _warnedAccess = access;
    GeolocalisationService.warnAccessRevoked(context, access);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _effectivelyEnabled(context.watch<FeatureFlagsState>());
    if (enabled != _lastEnabled) {
      _lastEnabled = enabled;
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
    return const SizedBox.shrink();
  }
}
