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

    class_attribute :configuration
    self.configuration = Configuration.new

    def self.configure(&blk)
      configuration.instance_eval(&blk)
    end

    def self.dupe
      dup.tap do |duplicated|
        duplicated.configuration = configuration.duplicate
      end
    end

    def self.duplicate(mod, controllers = 'Controllers', &blk)
      dupe.tap do |duplicated|
        mod.module_eval %{
          module #{ controllers }; end
          Action = Lotus::Action.dup
        }

        duplicated.module_eval %{
          configure do
            action_module #{mod}::Action
          end
        }

        duplicated.configure(&blk) if block_given?
      end
    end

    def self.included(base)
      conf = self.configuration.duplicate

      base.class_eval do
        include Dsl
        include Utils::ClassAttribute

        class_attribute :configuration
        self.configuration = conf
      end
    end
  end
end

