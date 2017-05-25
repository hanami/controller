source 'http://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',  '~> 1.0.0.beta1', require: false, github: 'hanami/utils',  branch: '1.0.x'
gem 'hanami-router', '~> 1.0.0.beta1', require: false, github: 'hanami/router', branch: '1.0.x'

group :validations do
  gem 'hanami-validations', '~> 1.0.0.beta1', require: false, github: 'hanami/validations', branch: '1.0.x'
end

gem 'coveralls', require: false
