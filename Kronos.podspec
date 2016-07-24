Pod::Spec.new do |s|
  s.name = 'Kronos'
  s.version = '0.0.5'
  s.license = 'Apache License, Version 2.0'
  s.summary = 'Elegant NTP client in Swift'
  s.homepage = 'https://github.com/lyft/Kronos'
  s.authors = { 'Martin Conte Mac Donell' => 'Reflejo@gmail.com' }
  s.source = { :git => 'git@github.com:/Lyft/Kronos.git', :tag => s.version }

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'Sources/*.swift'
end
