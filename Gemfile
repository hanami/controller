# frozen_string_literal: true

source 'http://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

unless ENV['CI']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',  '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/utils.git',  branch: 'main'
gem 'hanami-router', '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/router.git', branch: 'main'

group :validations do
  gem 'hanami-validations', '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/validations.git', branch: 'main'
end

group :test do
  gem 'dry-files',   '~> 0.1', github: 'dry-rb/dry-files', branch: 'master'

  gem 'hanami-cli',  '~> 2.0.alpha', github: 'hanami/cli', branch: 'main'
  gem 'hanami-view', '~> 2.0.alpha', github: 'hanami/view', branch: 'main'
  gem 'hanami',      '~> 2.0.alpha', github: 'hanami/hanami', branch: 'unstable'
  gem 'slim'
end

gem 'hanami-devtools', github: 'hanami/devtools', branch: 'main'

# Required until release of expanded dry-configurable `setting` keyword args API (and
# associated gem updates)
gem "dry-configurable", github: "dry-rb/dry-configurable", branch: "master"
gem "dry-system", github: "dry-rb/dry-system", branch: "master"
