Pod::Spec.new do |spec|
  spec.name                 = 'Navigine'
  spec.version              = '1.0.20'
  spec.license              = 'MIT'
  spec.summary              = "iOS SDK for performing indoor navigation"
  spec.platform             = :ios, "8.0"
  spec.homepage             = 'https://github.com/Navigine/navigine_ios_framework'
  spec.authors              = { 'Pavel Tychinin' => 'p.tychinin@navigine.com' }
  spec.source               = { :git => 'https://github.com/Navigine/navigine_ios_framework.git', :tag => 'v.1.0.20' }
  spec.documentation_url    = 'https://github.com/Navigine/navigine_ios_framework/wiki/Getting-Started'
  spec.vendored_frameworks  = 'Navigine Framework/Navigine.framework'
  spec.public_header_files  = 'Navigine Framework/Navigine.framework/Headers/*.h'
  spec.requires_arc         =  true
end