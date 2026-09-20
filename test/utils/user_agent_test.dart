import 'package:aelf_flutter/utils/user_agent.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Linux User-Agent used to crash on every point-release distribution.
///
/// `LinuxDeviceInfo.buildId` is `BUILD_ID` from `/etc/os-release`. Arch sets
/// it; Debian, Ubuntu and Fedora do not — and those are precisely what the
/// `debian/` and `snap/` packaging targets. Dereferencing it with `!` threw,
/// which took down `LiturgyState.initUserAgent` at startup.
void main() {
  group('linuxOsVersion', () {
    test('uses BUILD_ID when the distribution sets one (Arch)', () {
      expect(linuxOsVersion('arch', '2025.06.01', null), 'arch 2025.06.01');
    });

    test('falls back to VERSION_ID when BUILD_ID is absent (Ubuntu)', () {
      expect(linuxOsVersion('ubuntu', null, '24.04'), 'ubuntu 24.04');
    });

    test('falls back to VERSION_ID on Debian', () {
      expect(linuxOsVersion('debian', null, '12'), 'debian 12');
    });

    test('prefers BUILD_ID when both are present', () {
      expect(linuxOsVersion('arch', 'rolling', '2025'), 'arch rolling');
    });

    test('degrades to the id alone when neither is set', () {
      expect(linuxOsVersion('nixos', null, null), 'nixos');
    });

    test('treats empty and blank values as absent', () {
      expect(linuxOsVersion('ubuntu', '', '24.04'), 'ubuntu 24.04');
      expect(linuxOsVersion('ubuntu', '   ', '24.04'), 'ubuntu 24.04');
      expect(linuxOsVersion('ubuntu', '', ''), 'ubuntu');
    });

    test('never throws, whatever the os-release contains', () {
      for (final buildId in [null, '', 'x']) {
        for (final versionId in [null, '', 'y']) {
          expect(
              () => linuxOsVersion('id', buildId, versionId), returnsNormally,
              reason: 'buildId=$buildId versionId=$versionId');
        }
      }
    });
  });
}
