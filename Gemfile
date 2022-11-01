# frozen_string_literal: true

source "http://rubygems.org"

gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "hanami-utils",  "~> 2.0.beta", require: false, git: "https://github.com/hanami/utils.git",  branch: "main"
gem "hanami-router", "~> 2.0.beta", require: false, git: "https://github.com/hanami/router.git", branch: "main"

gem "dry-configurable", github: "dry-rb/dry-configurable"

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

group :benchmarks do
  gem "benchmark-memory"
  gem "memory_profiler"
end

gem "hanami-devtools", github: "hanami/devtools", branch: "main"
