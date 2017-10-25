source 'http://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',  '~> 1.1', require: false, git: 'https://github.com/hanami/utils.git',  branch: 'develop'
gem 'hanami-router', '~> 1.1', require: false, git: 'https://github.com/hanami/router.git', branch: 'develop'

group :validations do
  gem 'hanami-validations', '~> 1.1', require: false, git: 'https://github.com/hanami/validations.git', branch: 'develop'
end

gem 'coveralls', require: false
