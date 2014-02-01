Pod::Spec.new do |s|
  s.name         = "DNTCoreData"
  s.version      = "0.2.2"
  s.summary      = "A collection of Core Data related classes and categories."
  s.description  = <<-DESC
                    A collection of Core Data related classes and categories.
                   DESC
  s.homepage     = "http://danthorpe.me"
  s.license      = 'MIT'
  s.author       = { "Daniel Thorpe" => "dan@danthorpe.me" }
  s.source       = { :git => "https://github.com/danthorpe/DNTCoreData.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.ios.deployment_target = '6.0'
  s.requires_arc = true
  
  s.prefix_header_contents = '''

#ifdef __OBJC__

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define DNT_WEAK_SELF __weak __typeof(&*self)weakSelf = self;

#endif
'''

  s.source_files = 'Classes'
  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
  s.public_header_files = 'Classes/*.h', 'Classes/**/*.h'
  s.frameworks = 'CoreData'
  
  s.dependency 'CocoaLumberjack', '~> 1.7.0'

end
