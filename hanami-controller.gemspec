# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hanami/controller/version'

Gem::Specification.new do |spec|
  spec.name          = 'hanami-controller'
  spec.version       = Hanami::Controller::VERSION
  spec.authors       = ['Luca Guidi']
  spec.email         = ['me@lucaguidi.com']
  spec.description   = %q{Complete, fast and testable actions for Rack}
  spec.summary       = %q{Complete, fast and testable actions for Rack and Hanami}
  spec.homepage      = 'http://hanamirb.org'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -- lib/* CHANGELOG.md LICENSE.md README.md hanami-controller.gemspec`.split($/)
  spec.executables   = []
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'rack',         '~> 2.0'
  spec.add_dependency 'hanami-utils', '~> 2.0.alpha'
  spec.add_dependency 'dry-configurable', '~> 0.11' # FIXME: require latest patch release when available

  spec.add_development_dependency 'bundler',   '>= 1.6', '< 3'
  spec.add_development_dependency 'rack-test', '~> 1.0'
  spec.add_development_dependency 'rake',      '~> 13'
  spec.add_development_dependency 'rspec',     '~> 3.7'
end
