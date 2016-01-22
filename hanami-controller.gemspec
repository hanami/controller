# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hanami/controller/version'

Gem::Specification.new do |spec|
  spec.name          = 'hanami-controller'
  spec.version       = Hanami::Controller::VERSION
  spec.authors       = ['Luca Guidi', 'Trung Lê', 'Alfonso Uceda']
  spec.email         = ['me@lucaguidi.com', 'trung.le@ruby-journal.com', 'uceda73@gmail.com']
  spec.description   = %q{Complete, fast and testable actions for Rack}
  spec.summary       = %q{Complete, fast and testable actions for Rack and Hanami}
  spec.homepage      = 'http://hanamirb.org'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -- lib/* CHANGELOG.md LICENSE.md README.md hanami-controller.gemspec`.split($/)
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(test)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'rack',               '~> 1.6', '>= 1.6.2'
  spec.add_dependency 'hanami-utils',       '~> 0.7'
  spec.add_dependency 'hanami-validations', '~> 0.5'

  spec.add_development_dependency 'bundler',   '~> 1.6'
  spec.add_development_dependency 'minitest',  '~> 5'
  spec.add_development_dependency 'rack-test', '~> 0.6'
  spec.add_development_dependency 'rake',      '~> 10'
end
