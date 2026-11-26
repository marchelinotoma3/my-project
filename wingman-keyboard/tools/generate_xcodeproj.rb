# Regenerates Wingman.xcodeproj from the folders in this repo.
# Only needed if you add or remove source files:
#   gem install xcodeproj && ruby tools/generate_xcodeproj.rb
require 'xcodeproj'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(ROOT, 'Wingman.xcodeproj')
DEPLOYMENT_TARGET = '17.0'

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes['LastSwiftUpdateCheck'] = '1600'
project.root_object.attributes['LastUpgradeCheck'] = '1600'
project.root_object.development_region = 'en'
project.root_object.known_regions = %w[en Base]

def swift_files(dir)
  Dir[File.join(ROOT, dir, '*.swift')].sort.map { |f| File.basename(f) }
end

# Groups
config_group = project.main_group.new_group('Config', 'Config')
base_xcconfig = config_group.new_file('Base.xcconfig')
config_group.new_file('Secrets.example.xcconfig')
shared_group = project.main_group.new_group('Shared', 'Shared')
app_group = project.main_group.new_group('App', 'App')
keyboard_group = project.main_group.new_group('Keyboard', 'Keyboard')
project.main_group.new_file('README.md')
project.main_group.new_file('PLAYBOOK.md')

shared_refs = swift_files('Shared').map { |f| shared_group.new_file(f) }
app_refs = swift_files('App').map { |f| app_group.new_file(f) }
keyboard_refs = swift_files('Keyboard').map { |f| keyboard_group.new_file(f) }
assets_ref = app_group.new_file('Assets.xcassets')
app_group.new_file('Info.plist')
app_group.new_file('Wingman.entitlements')
keyboard_group.new_file('Info.plist')
keyboard_group.new_file('Keyboard.entitlements')

# Targets
app = project.new_target(:application, 'Wingman', :ios, DEPLOYMENT_TARGET)
keyboard = project.new_target(:app_extension, 'WingmanKeyboard', :ios, DEPLOYMENT_TARGET)

# new_target links Foundation by a path tied to one SDK version; Swift auto-links it anyway.
[app, keyboard].each do |target|
  target.frameworks_build_phase.files.dup.each do |build_file|
    ref = build_file.file_ref
    build_file.remove_from_project
    ref.remove_from_project if ref && ref.build_files.empty?
  end
end
project.frameworks_group.remove_from_project if project.frameworks_group.children.empty?

app.add_file_references(app_refs + shared_refs)
keyboard.add_file_references(keyboard_refs + shared_refs)
app.add_resources([assets_ref])

# Embed the keyboard in the app.
app.add_dependency(keyboard)
embed = app.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed_file = embed.add_file_reference(keyboard.product_reference, true)
embed_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

# Project-level settings come from Config/Base.xcconfig.
project.build_configurations.each do |config|
  config.base_configuration_reference = base_xcconfig
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['DEVELOPMENT_LANGUAGE'] = 'en'
end

common = {
  'CODE_SIGN_STYLE' => 'Automatic',
  'GENERATE_INFOPLIST_FILE' => 'NO',
  'SWIFT_VERSION' => '5.0',
  'TARGETED_DEVICE_FAMILY' => '1',
  'IPHONEOS_DEPLOYMENT_TARGET' => DEPLOYMENT_TARGET,
  'MARKETING_VERSION' => '1.0',
  'CURRENT_PROJECT_VERSION' => '1',
  'ENABLE_USER_SCRIPT_SANDBOXING' => 'YES',
}

app.build_configurations.each do |config|
  config.build_settings.merge!(common)
  config.build_settings.merge!(
    'PRODUCT_NAME' => 'Wingman',
    'PRODUCT_BUNDLE_IDENTIFIER' => '$(WINGMAN_BUNDLE_PREFIX).wingman',
    'INFOPLIST_FILE' => 'App/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'App/Wingman.entitlements',
    'ASSETCATALOG_COMPILER_APPICON_NAME' => 'AppIcon',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks'],
    'ENABLE_PREVIEWS' => 'YES',
  )
end

keyboard.build_configurations.each do |config|
  config.build_settings.merge!(common)
  config.build_settings.merge!(
    'PRODUCT_NAME' => 'WingmanKeyboard',
    'PRODUCT_BUNDLE_IDENTIFIER' => '$(WINGMAN_BUNDLE_PREFIX).wingman.keyboard',
    'INFOPLIST_FILE' => 'Keyboard/Info.plist',
    'CODE_SIGN_ENTITLEMENTS' => 'Keyboard/Keyboard.entitlements',
    'SKIP_INSTALL' => 'YES',
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'LD_RUNPATH_SEARCH_PATHS' => ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks'],
  )
end

project.save

# A shared scheme so "Wingman" is ready to run as soon as the project opens.
scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app, nil, launch_target: true)
scheme.save_as(PROJECT_PATH, 'Wingman', true)

puts "Wrote #{PROJECT_PATH}"
puts "  app sources: #{app_refs.size} + shared #{shared_refs.size}"
puts "  keyboard sources: #{keyboard_refs.size} + shared #{shared_refs.size}"
