require 'rubygems'
require 'bundler/setup'

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  SimpleCov.start do
    command_name 'test'
    add_filter   'test'
  end
end

require 'minitest/autorun'
$:.unshift 'lib'
require 'hanami/controller'
require 'hanami/action/cookies'
require 'hanami/action/session'

Hanami::Controller.class_eval do
  def self.unload!
    self.configuration = configuration.duplicate
    configuration.reset!
  end
end

require 'fixtures'

Hanami::Controller::Configuration.class_eval do
  def ==(other)
    other.kind_of?(self.class) &&
      other.handle_exceptions  == handle_exceptions &&
      other.handled_exceptions == handled_exceptions &&
      other.action_module      == action_module
  end

  public :handled_exceptions
end
