Pod::Spec.new do |s|
  s.name = 'Kronos'
  s.version = '4.2.1'
  s.license = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
  s.summary = 'Elegant NTP client in Swift'
  s.homepage = 'https://github.com/MobileNativeFoundation/Kronos'
  s.authors = { 'Martin Conte Mac Donell' => 'Reflejo@gmail.com' }
  s.source = { :git => 'https://github.com/MobileNativeFoundation/Kronos.git', :tag => s.version }
  s.swift_versions = ['5.0', '5.2']

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'

  s.source_files = 'Sources/*.swift'
end
