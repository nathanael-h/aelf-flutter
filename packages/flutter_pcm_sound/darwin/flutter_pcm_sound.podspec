#
# Only used when Swift Package Manager is disabled: the app builds this plugin
# through darwin/flutter_pcm_sound/Package.swift.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_pcm_sound'
  s.version          = '3.3.3'
  s.summary          = 'Flutter plugin for PCM sound'
  s.description      = 'Flutter plugin for PCM sound'
  s.homepage         = 'https://github.com/chipweinberger/flutter_pcm_sound'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Chip Weinberger' => 'weinbergerc@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_pcm_sound/Sources/flutter_pcm_sound/**/*.{h,m}'
  s.public_header_files = 'flutter_pcm_sound/Sources/flutter_pcm_sound/include/**/*.h'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.framework = 'AudioToolbox'
  s.ios.framework = 'AVFoundation'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
