source 'http://rubygems.org'
gemspec

unless ENV['CI']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',  '~> 1.3', require: false, git: 'https://github.com/hanami/utils.git',  branch: '1.3.x'
gem 'hanami-router', '~> 1.3', require: false, git: 'https://github.com/hanami/router.git', branch: '1.3.x'
gem 'dry-configurable', '0.12.1'

group :validations do
  if ENV['HANAMI_VALIDATIONS'] == '2'
    gem 'hanami-validations', '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/validations.git', branch: 'main'
  else
    gem 'hanami-validations', '~> 1.3', require: false, git: 'https://github.com/hanami/validations.git', branch: '1.3.x'
  end
end

gem 'hanami-devtools', require: false, git: 'https://github.com/hanami/devtools.git', branch: '1.3.x'
