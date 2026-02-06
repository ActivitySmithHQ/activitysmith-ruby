# frozen_string_literal: true

require_relative "lib/activitysmith/version"

Gem::Specification.new do |spec|
  spec.name          = "activitysmith"
  spec.version       = ActivitySmith::VERSION
  spec.authors       = ["ActivitySmith"]
  spec.email         = ["adam@activitysmith.com"]

  spec.summary       = "Official ActivitySmith Ruby SDK"
  spec.description   = "Official ActivitySmith Ruby SDK"
  spec.homepage      = "https://activitysmith.com/docs/sdks/ruby"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ActivitySmithHQ/activitysmith-ruby"

  spec.files = Dir.glob([
    "lib/**/*.rb",
    "generated/**/*",
    "README.md",
    "LICENSE"
  ])

  spec.require_paths = ["lib"]

  spec.add_dependency "json", ">= 2.3"
  spec.add_dependency "typhoeus", ">= 1.0"

  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "rake", ">= 13.0"
end
