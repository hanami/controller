require 'lotus/utils/class_attribute'
require 'lotus/action'
require 'lotus/controller/configuration'
require 'lotus/controller/dsl'
require 'lotus/controller/version'
require 'rack-patch'

module Lotus
  # A set of logically grouped actions
  #
  # @since 0.1.0
  #
  # @see Lotus::Action
  #
  # @example
  #   require 'lotus/controller'
  #
  #   class ArticlesController
  #     include Lotus::Controller
  #
  #     action 'Index' do
  #       # ...
  #     end
  #
  #     action 'Show' do
  #       # ...
  #     end
  #   end
  module Controller
    include Utils::ClassAttribute

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure(&blk)
      configuration.instance_eval(&blk)
    end

    def self.included(base)
      base.class_eval do
        include Dsl
      end
    end
  end
end

