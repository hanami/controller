source 'http://rubygems.org'
gemspec

unless ENV['CI']
  gem 'byebug', require: false, platforms: :mri
  gem 'yard',   require: false
end

gem 'hanami-utils',  '~> 1.3', require: false, git: 'https://github.com/hanami/utils.git',  branch: '1.3.x'
gem 'hanami-router', '~> 1.3', require: false, git: 'https://github.com/hanami/router.git', branch: '1.3.x'

case RUBY_VERSION
when /\A2\.3/
  gem 'dry-configurable', '0.8.3'
when /\A2\.4/
  gem 'dry-configurable', '0.11.6'
else
  gem 'dry-configurable', '0.12.1'
end

group :validations do
  if ENV['HANAMI_VALIDATIONS'] == '2'
    gem 'hanami-validations', '~> 2.0.alpha', require: false, git: 'https://github.com/hanami/validations.git', branch: 'main'
  else
    gem 'hanami-validations', '~> 1.3', require: false, git: 'https://github.com/hanami/validations.git', branch: '1.3.x'
  end
end

gem 'hanami-devtools', require: false, git: 'https://github.com/hanami/devtools.git', branch: '1.3.x'
