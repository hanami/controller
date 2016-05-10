source 'http://rubygems.org'
gemspec

unless ENV['TRAVIS']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',       '~> 0.8', require: false, github: 'hanami/utils',       branch: '0.8.x'
gem 'hanami-router',      '~> 0.7', require: false, github: 'hanami/router',      branch: '0.7.x'

group :validations do
  gem 'hanami-validations', '~> 0.6', require: false, github: 'hanami/validations', branch: 'predicates-with-new-backend'

  # This is required until dry-validation 0.8 will be out
  gem 'dry-types',                    require: false, github: 'dry-rb/dry-types'
  gem 'dry-logic',                    require: false, github: 'dry-rb/dry-logic'
  gem 'dry-validation',               require: false, github: 'dry-rb/dry-validation'
end

gem 'minitest-line'
gem 'coveralls', require: false
