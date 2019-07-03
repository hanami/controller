source 'http://rubygems.org'
gemspec

unless ENV['CI']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',  '~> 1.3', require: false, git: 'https://github.com/hanami/utils.git',  branch: 'master'
gem 'hanami-router', '~> 1.3', require: false, git: 'https://github.com/hanami/router.git', branch: 'master'

group :validations do
  if ENV['HANAMI_VALIDATIONS'] == '2'
    gem 'hanami-validations', '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/validations.git', branch: 'feature/hanami-validator'
  else
    gem 'hanami-validations', '~> 1.3', require: false, git: 'https://github.com/hanami/validations.git', branch: 'master'
  end
end

gem 'hanami-devtools', require: false, git: 'https://github.com/hanami/devtools.git'
