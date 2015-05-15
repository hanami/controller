require 'lotus/utils/class_attribute'
require 'lotus/action'
require 'lotus/controller/configuration'
require 'lotus/controller/version'

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
  #   module Articles
  #     class Index
  #       include Lotus::Action
  #
  #       # ...
  #     end
  #
  #     class Show
  #       include Lotus::Action
  #
  #       # ...
  #     end
  #   end
  module Controller
    # Unknown format error
    #
    # This error is raised when a action sets a format that it isn't recognized
    # both by `Lotus::Controller::Configuration` and the list of Rack mime types
    #
    # @since 0.2.0
    #
    # @see Lotus::Action::Mime#format=
    class UnknownFormatError < ::StandardError
      def initialize(format)
        super("Cannot find a corresponding Mime type for '#{ format }'. Please configure it with Lotus::Controller::Configuration#format.")
      end
    end

    include Utils::ClassAttribute

    # Framework configuration
    #
    # @since 0.2.0
    # @api private
    class_attribute :configuration
    self.configuration = Configuration.new

    # Configure the framework.
    # It yields the given block in the context of the configuration
    #
    # @param blk [Proc] the configuration block
    #
    # @since 0.2.0
    #
    # @see Lotus::Controller::Configuration
    #
    # @example
    #   require 'lotus/controller'
    #
    #   Lotus::Controller.configure do
    #     handle_exceptions false
    #   end
    def self.configure(&blk)
      configuration.instance_eval(&blk)
    end

    # Duplicate Lotus::Controller in order to create a new separated instance
    # of the framework.
    #
    # The new instance of the framework will be completely decoupled from the
    # original. It will inherit the configuration, but all the changes that
    # happen after the duplication, won't be reflected on the other copies.
    #
    # @return [Module] a copy of Lotus::Controller
    #
    # @since 0.2.0
    # @api private
    #
    # @example Basic usage
    #   require 'lotus/controller'
    #
    #   module MyApp
    #     Controller = Lotus::Controller.dupe
    #   end
    #
    #   MyApp::Controller == Lotus::Controller # => false
    #
    #   MyApp::Controller.configuration ==
    #     Lotus::Controller.configuration # => false
    #
    # @example Inheriting configuration
    #   require 'lotus/controller'
    #
    #   Lotus::Controller.configure do
    #     handle_exceptions false
    #   end
    #
    #   module MyApp
    #     Controller = Lotus::Controller.dupe
    #   end
    #
    #   module MyApi
    #     Controller = Lotus::Controller.dupe
    #     Controller.configure do
    #       handle_exceptions true
    #     end
    #   end
    #
    #   Lotus::Controller.configuration.handle_exceptions # => false
    #   MyApp::Controller.configuration.handle_exceptions # => false
    #   MyApi::Controller.configuration.handle_exceptions # => true
    def self.dupe
      dup.tap do |duplicated|
        duplicated.configuration = configuration.duplicate
      end
    end

    # Duplicate the framework and generate modules for the target application
    #
    # @param mod [Module] the Ruby namespace of the application
    # @param controllers [String] the optional namespace where the application's
    #   controllers will live
    # @param blk [Proc] an optional block to configure the framework
    #
    # @return [Module] a copy of Lotus::Controller
    #
    # @since 0.2.0
    #
    # @see Lotus::Controller#dupe
    # @see Lotus::Controller::Configuration
    # @see Lotus::Controller::Configuration#action_module
    #
    # @example Basic usage
    #   require 'lotus/controller'
    #
    #   module MyApp
    #     Controller = Lotus::Controller.duplicate(self)
    #   end
    #
    #   # It will:
    #   #
    #   # 1. Generate MyApp::Controller
    #   # 2. Generate MyApp::Action
    #   # 3. Generate MyApp::Controllers
    #   # 4. Configure MyApp::Action as the default module for actions
    #
    #  module MyApp::Controllers::Dashboard
    #    include MyApp::Controller
    #
    #    action 'Index' do # this will inject MyApp::Action
    #      def call(params)
    #        # ...
    #      end
    #    end
    #  end
    #
    # @example Compare code
    #   require 'lotus/controller'
    #
    #   module MyApp
    #     Controller = Lotus::Controller.duplicate(self) do
    #       # ...
    #     end
    #   end
    #
    #   # it's equivalent to:
    #
    #   module MyApp
    #     Controller = Lotus::Controller.dupe
    #     Action     = Lotus::Action.dup
    #
    #     module Controllers
    #     end
    #
    #     Controller.configure do
    #       action_module MyApp::Action
    #     end
    #
    #     Controller.configure do
    #       # ...
    #     end
    #   end
    #
    # @example Custom controllers module
    #   require 'lotus/controller'
    #
    #   module MyApp
    #     Controller = Lotus::Controller.duplicate(self, 'Ctrls')
    #   end
    #
    #   defined?(MyApp::Controllers) # => nil
    #   defined?(MyApp::Ctrls)       # => "constant"
    #
    #   # Developers can namespace controllers under Ctrls
    #   module MyApp::Ctrls::Dashboard
    #     # ...
    #   end
    #
    # @example Nil controllers module
    #   require 'lotus/controller'
    #
    #   module MyApp
    #     Controller = Lotus::Controller.duplicate(self, nil)
    #   end
    #
    #   defined?(MyApp::Controllers) # => nil
    #
    #   # Developers can namespace controllers under MyApp
    #   module MyApp::DashboardController
    #     # ...
    #   end
    #
    # @example Block usage
    #   require 'lotus/controller'
    #
    #   module MyApp
    #     Controller = Lotus::Controller.duplicate(self) do
    #       handle_exceptions false
    #     end
    #   end
    #
    #   Lotus::Controller.configuration.handle_exceptions # => true
    #   MyApp::Controller.configuration.handle_exceptions # => false
    def self.duplicate(mod, controllers = 'Controllers', &blk)
      dupe.tap do |duplicated|
        mod.module_eval %{ module #{ controllers }; end } if controllers
        mod.module_eval %{ Action = Lotus::Action.dup }

        duplicated.module_eval %{
          configure do
            action_module #{ mod }::Action
          end
        }

        duplicated.configure(&blk) if block_given?
      end
    end

    # Framework loading entry point
    #
    # @return [void]
    #
    # @since 0.3.0
    def self.load!
      configuration.load!
    end
  end
end

