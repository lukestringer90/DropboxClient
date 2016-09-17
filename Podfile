# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

target 'Dropbox Client' do
    use_frameworks!
    
    # Pods for Dropbox Client
    pod 'SwiftyDropbox'
    pod 'SwiftyTimer', git: 'https://github.com/radex/SwiftyTimer.git', branch: 'swift3'
    pod 'Result'
    
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.0'
        end
    end
end
