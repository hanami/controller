source 'http://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',  '~> 1.0', require: false, git: 'https://github.com/hanami/utils.git',  branch: '1.0.x'
gem 'hanami-router', '~> 1.0', require: false, git: 'https://github.com/hanami/router.git', branch: '1.0.x'

group :validations do
  gem 'hanami-validations', '~> 1.0', require: false, git: 'https://github.com/hanami/validations.git', branch: '1.0.x'
end

gem 'coveralls', require: false
