#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint hello.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'traffic_statistics'
  s.version          = '0.0.1+1'
  s.summary          = 'A plugin for getting network traffic speed and usage statistics'
  s.description      = <<-DESC
A plugin for getting network traffic speed and usage statistics
                       DESC
  s.homepage         = 'https://github.com/wolfe719/traffic_statistics'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'wolfe@lobo.us' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency       'RealReachability'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
