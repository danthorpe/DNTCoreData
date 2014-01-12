Pod::Spec.new do |s|
  s.name         = "DNTCoreData"
  s.version      = "0.1.1"
  s.summary      = "A collection of Core Data related classes and categories."
  s.description  = <<-DESC
                    A collection of Core Data related classes and categories.
                   DESC
  s.homepage     = "http://danthorpe.me"
  s.license      = 'MIT'
  s.author       = { "Daniel Thorpe" => "dan@danthorpe.me" }
  s.source       = { :git => "git@github.com/danthorpe/DNTCoreData.git", :tag => s.version.to_s }

  s.platform     = :ios, '5.0'
  s.ios.deployment_target = '5.0'
  s.requires_arc = true

  s.source_files = 'Classes'
  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
  s.public_header_files = 'Classes/*.h', 'Classes/**/*.h'
  s.frameworks = 'CoreData'

end
