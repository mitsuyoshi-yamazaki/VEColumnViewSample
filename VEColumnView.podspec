Pod::Spec.new do |s|
  s.name         = "VEColumnView"
  s.version      = "1.0"
  s.summary      = "Pinterest like UI"
  s.homepage     = ""
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Mitsuyoshi Yamazaki" => "yamazaki.mitsuyoshi@gmail.com" }
  s.source       = {  }
  s.platform     = :ios, '5.0'
  s.ios.deployment_target = '5.0'
  s.source_files = 'VEColumnView/VEColumnView.{h,m}'
  s.requires_arc = true
end
