source 'http://rubygems.org'
gemspec

unless ENV['CI']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',  '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/utils.git',  branch: 'unstable'
gem 'hanami-router', '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/router.git', branch: 'unstable'

group :validations do
  gem 'hanami-validations', '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/validations.git', branch: 'unstable'
end

gem 'hanami-devtools', require: false, git: 'https://github.com/hanami/devtools.git'
