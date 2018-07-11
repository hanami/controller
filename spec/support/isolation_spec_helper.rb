require 'rubygems'
require 'bundler'
Bundler.setup(:default, :development, :test)

$LOAD_PATH.unshift 'lib'
require 'hanami/controller'
require_relative './rspec'
require 'hanami/devtools/unit'

module RSpec
  module Support
    module Runner
      def self.run
        Core::Runner.autorun
      end
    end
  end
end
