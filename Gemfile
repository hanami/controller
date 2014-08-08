source 'http://rubygems.org'

gemspec

if !ENV['TRAVIS']
  gem 'byebug',       require: false, platforms: :mri if RUBY_VERSION >= '2.1.0'
  gem 'yard',         require: false
  gem 'lotus-router', require: false, github: 'lotus/router'
else
  gem 'lotus-router', require: false
end

gem 'lotus-utils',       require: false, github: 'lotus/utils'
gem 'lotus-validations', require: false, github: 'lotus/validations'
gem 'simplecov',         require: false
gem 'coveralls',         require: false
