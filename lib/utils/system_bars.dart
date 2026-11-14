import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

const _displayChannel = MethodChannel('aelf_flutter/display');

/// Shows the status bar on every platform.
/// Android: hides the navigation bar, a swipe from the bottom edge brings it
/// back for a few seconds (MainActivity.applySystemBars, also re-applied
/// natively on resume and focus). SystemChrome can't do this: its sticky
/// mode hides the status bar too.
/// iOS: the home indicator stays as is.
void applySystemBars() {
  if (kIsWeb) return;
  if (Platform.isAndroid) {
    _displayChannel.invokeMethod('applySystemBars');
  } else if (Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }
}
