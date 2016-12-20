source 'http://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'minitest',      '~> 5.8'
gem 'hanami-utils', '~> 0.9', require: false, github: 'alexd16/utils', branch: 'non-deep-symbolize'
gem 'hanami-router', '~> 0.8', require: false, github: 'hanami/router', branch: '0.8.x'

group :validations do
  gem 'hanami-validations', '~> 0.7', require: false, github: 'hanami/validations', branch: '0.7.x'
end

gem 'coveralls', require: false
