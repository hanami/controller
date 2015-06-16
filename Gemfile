source 'http://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri if RUBY_VERSION >= '2.1.0'
  gem 'yard',   require: false
end

gem 'lotus-utils',       '~> 0.5', require: false, github: 'lotus/utils',       branch: '0.5.x'
gem 'lotus-router',      '~> 0.4', require: false, github: 'lotus/router',      branch: '0.4.x'
gem 'lotus-validations', '~> 0.3', require: false, github: 'lotus/validations', branch: '0.3.x'

gem 'simplecov', require: false
gem 'coveralls', require: false
