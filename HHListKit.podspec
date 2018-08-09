Pod::Spec.new do |s|
  s.name         = 'HHListKit'
  s.summary      = 'Friend extension for ASCollectionNode and ASTableNode to make them easy to use'
  s.version      = '0.0.1'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { 'shellhue' => 'shellhue@gmail.com' }
  s.homepage     = 'https://github.com/shellhue/HHListKit'
  s.platform     = :ios, '9.0'
  s.ios.deployment_target = '9.0'
  s.source       = { :git => 'https://github.com/shellhue/HHListKit.git', :tag => s.version.to_s }
  
  s.requires_arc = true
  s.source_files = 'HHListKit/**/*.{h,m}'
  s.public_header_files = 'HHListKit/**/*.{h}'
  
  s.frameworks = 'UIKit', 'CoreFoundation'

  s.dependency "Texture/Core", "~> 2.7"
  s.dependency "Aspects", "~> 1.3.0"

end