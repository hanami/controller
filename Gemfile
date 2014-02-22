source 'http://rubygems.org'

gemspec

if !ENV['TRAVIS']
  gem 'debugger',     require: false
  gem 'yard',         require: false
  gem 'lotus-utils',  require: false, path: '../lotus-utils'
  gem 'lotus-router', require: false, path: '../lotus-router'
else
  gem 'lotus-router', require: false
end

gem 'simplecov', require: false
gem 'coveralls', require: false
