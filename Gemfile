# frozen_string_literal: true

source "http://rubygems.org"
gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "hanami-utils",  "~> 1.2", require: false, git: "https://github.com/hanami/utils.git",  branch: "master"
gem "hanami-router", "~> 1.2", require: false, git: "https://github.com/hanami/router.git", branch: "master"

group :validations do
  gem "hanami-validations", "~> 1.2", require: false, git: "https://github.com/hanami/validations.git", branch: "master"
end

gem "hanami-devtools", require: false, git: "https://github.com/hanami/devtools.git"
