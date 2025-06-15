platform :ios, '17.6'
use_frameworks!

target 'instapicture' do
  pod 'SwiftyJSON'
  pod 'SwiftHTTP'
  pod 'Locksmith'
  pod 'NotificationBannerSwift', '~> 3.0.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "17.6"
    end
  end
end
