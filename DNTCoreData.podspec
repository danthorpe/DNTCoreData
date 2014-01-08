#
# Be sure to run `pod spec lint NAME.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# To learn more about the attributes see http://docs.cocoapods.org/specification.html
#
Pod::Spec.new do |s|
  s.name         = "DNTCoreData"
  s.version      = "0.1.0"
  s.summary      = "A collection of Core Data related classes and categories."
  s.description  = <<-DESC
                    
                   DESC
  s.homepage     = "http://danthorpe.me"
  s.license      = 'MIT'
  s.author       = { "Daniel Thorpe" => "dan@danthorpe.me" }
  s.source       = { :git => "git@github.com/danthorpe/DNTCoreData.git", :tag => s.version.to_s }

  # s.platform     = :ios, '5.0'
  # s.ios.deployment_target = '5.0'
  # s.osx.deployment_target = '10.7'
  s.requires_arc = true

  s.source_files = 'Classes'
  s.resources = 'Assets'

  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
  # s.public_header_files = 'Classes/**/*.h'
  s.frameworks = 'CoreData'
  #s.dependency 'JSONKit', '~> 1.4'
end
