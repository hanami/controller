require 'rubygems'
require 'bundler/setup'

if ENV['COVERALL']
  require 'coveralls'
  Coveralls.wear!
end

require 'minitest/autorun'
$:.unshift 'lib'
require 'hanami/controller'
require 'hanami/action/cookies'
require 'hanami/action/session'

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
