# frozen_string_literal: true

source "http://rubygems.org"

gemspec

unless ENV["CI"]
  gem "byebug", require: false, platforms: :mri
  gem "yard",   require: false
end

gem "hanami-utils",  "~> 2.0.beta", require: false, git: "https://github.com/hanami/utils.git",  branch: "main"
gem "hanami-router", "~> 2.0.beta", require: false, git: "https://github.com/hanami/router.git", branch: "main"

gem "dry-auto_inject", github: "dry-rb/dry-auto_inject"
gem "dry-configurable", github: "dry-rb/dry-configurable"
gem "dry-core", github: "dry-rb/dry-core"
gem "dry-events", github: "dry-rb/dry-events"
gem "dry-logic", github: "dry-rb/dry-logic"
gem "dry-monitor", github: "dry-rb/dry-monitor"
gem "dry-schema", github: "dry-rb/dry-schema"
gem "dry-system", github: "dry-rb/dry-system"
gem "dry-types", github: "dry-rb/dry-types"
gem "dry-validation", github: "dry-rb/dry-validation"

group :validations do
  gem "hanami-validations", "~> 2.0.beta", require: false, git: "https://github.com/hanami/validations.git",
                                           branch: "main"
end

group :test do
  gem "dry-files", github: "dry-rb/dry-files", branch: "main"

  gem "hanami-cli",  github: "hanami/cli", branch: "main"
  gem "hanami-view", github: "hanami/view", branch: "use-dry-rb-1.0.0rc"
  gem "hanami",      github: "hanami/hanami", branch: "main"
  gem "slim"
end

group :benchmarks do
  gem "benchmark-memory"
  gem "memory_profiler"
end

gem "hanami-devtools", github: "hanami/devtools", branch: "main"
