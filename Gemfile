# frozen_string_literal: true

source "http://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "hanami-utils",  "~> 2.0.beta", require: false, git: "https://github.com/hanami/utils.git",  branch: "main"
gem "hanami-router", "~> 2.0.beta", require: false, git: "https://github.com/hanami/router.git", branch: "main"

group :validations do
  gem "hanami-validations", "~> 2.0.beta", require: false, git: "https://github.com/hanami/validations.git",
                                           branch: "main"
end

group :test do
  gem "dry-files", github: "dry-rb/dry-files", branch: "main"

  gem "hanami-cli",  github: "hanami/cli", branch: "main"
  gem "hanami-view", github: "hanami/view", branch: "main"
  gem "hanami",      github: "hanami/hanami", branch: "main"
  gem "slim"
end

gem "hanami-devtools", github: "hanami/devtools", branch: "main"
