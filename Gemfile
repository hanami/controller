# frozen_string_literal: true

source "http://rubygems.org"

gemspec

unless ENV["CI"]
  gem "byebug", platforms: :mri
  gem "yard"
  gem "yard-junk"
end

gem "hanami-utils",  github: "hanami/utils", branch: "main"
gem "hanami-router", github: "hanami/router", branch: "main"

group :validations do
  gem "hanami-validations", github: "hanami/validations", branch: "main"
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
