# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'Dropbox Client' do
  use_frameworks!

  # Pods for Dropbox Client
  pod 'SwiftyDropbox'
  pod 'SwiftyTimer'
  pod 'Result', '~> 2.1.3'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '2.3'
        end
    end
end
