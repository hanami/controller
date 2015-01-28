source 'http://rubygems.org'

gemspec

if !ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri if RUBY_VERSION >= '2.1.0'
  gem 'yard',   require: false
end

gem 'lotus-utils',       '~> 0.3', '>= 0.3.1.dev', require: false, github: 'lotus/utils',       branch: '0.3.x'
gem 'lotus-router',                '>= 0.2.0.dev', require: false, github: 'lotus/router',      branch: '0.2.x'
gem 'lotus-validations',           '>= 0.2.0.dev', require: false, github: 'lotus/validations', branch: 'master'

gem 'simplecov', require: false
gem 'coveralls', require: false
