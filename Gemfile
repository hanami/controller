# frozen_string_literal: true

source 'http://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gemspec

unless ENV['CI']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'dry-configurable', github: "dry-rb/dry-configurable", branch: "evaluate-setting-if-input-defined"
gem 'hanami-utils',  '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/utils.git',  branch: 'unstable'
gem 'hanami-router', '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/router.git', branch: 'unstable'

group :validations do
  gem 'hanami-validations', '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/validations.git', branch: 'unstable'
end

# group :development do
#   gem 'pry'
# end

group :test do
  gem 'hanami', github: 'hanami/hanami', branch: 'unstable'
  gem 'hanami-view', github: 'hanami/view', branch: 'master'
  gem 'slim'
end

gem 'hanami-devtools', github: 'hanami/devtools'
