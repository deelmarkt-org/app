source "https://rubygems.org"

# Fastlane for iOS / Android metadata + screenshot uploads.
# Pinned to match fastlane_version declared in fastlane/Fastfile.
gem "fastlane", "~> 2.220"

plugins_path = File.join(File.dirname(__FILE__), "fastlane", "Pluginfile")
eval_gemfile(plugins_path) if File.exist?(plugins_path)
