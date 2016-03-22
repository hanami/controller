source 'http://rubygems.org'
gemspec

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',       '~> 0.8', require: false, github: 'hanami/utils',       branch: '0.8.x'
gem 'hanami-router',      '~> 0.7', require: false, github: 'hanami/router',      branch: '0.7.x'
gem 'hanami-validations', '~> 0.6', require: false, github: 'hanami/validations', branch: '0.6.x'

gem 'coveralls', require: false
