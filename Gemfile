# frozen_string_literal: true

source "http://rubygems.org"

gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "hanami-utils",  "~> 2.0.beta", require: false, git: "https://github.com/hanami/utils.git",  branch: "main"
gem "hanami-router", "~> 2.0.beta", require: false, git: "https://github.com/hanami/router.git", branch: "main"

gem "dry-auto_inject", github: "dry-rb/dry-auto_inject", branch: "main"
gem "dry-configurable", github: "dry-rb/dry-configurable", branch: "main"
gem "dry-cli", github: "dry-rb/dry-cli", branch: "main"
gem "dry-core", github: "dry-rb/dry-core", branch: "main"
gem "dry-events", github: "dry-rb/dry-events", branch: "main"
gem "dry-inflector", github: "dry-rb/dry-inflector", branch: "main"
gem "dry-logic", github: "dry-rb/dry-logic", branch: "main"
gem "dry-monitor", github: "dry-rb/dry-monitor", branch: "main"
gem "dry-schema", github: "dry-rb/dry-schema", branch: "main"
gem "dry-system", github: "dry-rb/dry-system", branch: "main"
gem "dry-types", github: "dry-rb/dry-types", branch: "main"
gem "dry-validation", github: "dry-rb/dry-validation", branch: "main"

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
