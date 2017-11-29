source 'http://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',  '~> 1.1', require: false, git: 'https://github.com/hanami/utils.git',  branch: '1.1.x'
gem 'hanami-router', '~> 1.1', require: false, git: 'https://github.com/hanami/router.git', branch: '1.1.x'

group :validations do
  gem 'hanami-validations', '~> 1.1', require: false, git: 'https://github.com/hanami/validations.git', branch: '1.1.x'
end

gem 'coveralls', require: false
