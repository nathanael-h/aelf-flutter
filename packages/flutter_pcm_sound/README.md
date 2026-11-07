# flutter_pcm_sound (local copy)

Copy of [flutter_pcm_sound](https://github.com/chipweinberger/flutter_pcm_sound)
3.3.3, which is in the public domain (see `LICENSE`). The app uses it to play
the psalm tones (`lib/utils/tone_player.dart`).

The published package only ships CocoaPods podspecs. That makes Flutter fall
back to CocoaPods for the whole app, which otherwise builds with Swift Package
Manager only. This copy differs in a single point: its iOS and macOS sources,
which were identical, are shared in `darwin/` and built by
`darwin/flutter_pcm_sound/Package.swift` (with a podspec kept for builds where
Swift Package Manager is disabled). The header imports `TargetConditionals.h`,
which a Swift Package does not get from a prefix header.

The Dart and Android code is unchanged. Once the published package has a
Swift Package, the app can go back to it and this folder can be deleted.
