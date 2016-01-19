require 'hanami/utils/class_attribute'
require 'hanami/action'
require 'hanami/controller/configuration'
require 'hanami/controller/version'
require 'hanami/controller/error'

module Hanami
  # A set of logically grouped actions
  #
  # @since 0.1.0
  #
  # @see Hanami::Action
  #
  # @example
  #   require 'hanami/controller'
  #
  #   module Articles
  #     class Index
  #       include Hanami::Action
  #
  #       # ...
  #     end
  #
  #     class Show
  #       include Hanami::Action
  #
  #       # ...
  #     end
  #   end
  module Controller
    # Unknown format error
    #
    # This error is raised when a action sets a format that it isn't recognized
    # both by `Hanami::Controller::Configuration` and the list of Rack mime types
    #
    # @since 0.2.0
    #
    # @see Hanami::Action::Mime#format=
    class UnknownFormatError < Hanami::Controller::Error
      def initialize(format)
        super("Cannot find a corresponding Mime type for '#{ format }'. Please configure it with Hanami::Controller::Configuration#format.")
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
    # @see Hanami::Controller::Configuration
    #
    # @example
    #   require 'hanami/controller'
    #
    #   Hanami::Controller.configure do
    #     handle_exceptions false
    #   end
    def self.configure(&blk)
      configuration.instance_eval(&blk)
    end

    # Duplicate Hanami::Controller in order to create a new separated instance
    # of the framework.
    #
    # The new instance of the framework will be completely decoupled from the
    # original. It will inherit the configuration, but all the changes that
    # happen after the duplication, won't be reflected on the other copies.
    #
    # @return [Module] a copy of Hanami::Controller
    #
    # @since 0.2.0
    # @api private
    #
    # @example Basic usage
    #   require 'hanami/controller'
    #
    #   module MyApp
    #     Controller = Hanami::Controller.dupe
    #   end
    #
    #   MyApp::Controller == Hanami::Controller # => false
    #
    #   MyApp::Controller.configuration ==
    #     Hanami::Controller.configuration # => false
    #
    # @example Inheriting configuration
    #   require 'hanami/controller'
    #
    #   Hanami::Controller.configure do
    #     handle_exceptions false
    #   end
    #
    #   module MyApp
    #     Controller = Hanami::Controller.dupe
    #   end
    #
    #   module MyApi
    #     Controller = Hanami::Controller.dupe
    #     Controller.configure do
    #       handle_exceptions true
    #     end
    #   end
    #
    #   Hanami::Controller.configuration.handle_exceptions # => false
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
    # @return [Module] a copy of Hanami::Controller
    #
    # @since 0.2.0
    #
    # @see Hanami::Controller#dupe
    # @see Hanami::Controller::Configuration
    # @see Hanami::Controller::Configuration#action_module
    #
    # @example Basic usage
    #   require 'hanami/controller'
    #
    #   module MyApp
    #     Controller = Hanami::Controller.duplicate(self)
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
    #   require 'hanami/controller'
    #
    #   module MyApp
    #     Controller = Hanami::Controller.duplicate(self) do
    #       # ...
    #     end
    #   end
    #
    #   # it's equivalent to:
    #
    #   module MyApp
    #     Controller = Hanami::Controller.dupe
    #     Action     = Hanami::Action.dup
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
    #   require 'hanami/controller'
    #
    #   module MyApp
    #     Controller = Hanami::Controller.duplicate(self, 'Ctrls')
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
    #   require 'hanami/controller'
    #
    #   module MyApp
    #     Controller = Hanami::Controller.duplicate(self, nil)
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
    #   require 'hanami/controller'
    #
    #   module MyApp
    #     Controller = Hanami::Controller.duplicate(self) do
    #       handle_exceptions false
    #     end
    #   end
    #
    #   Hanami::Controller.configuration.handle_exceptions # => true
    #   MyApp::Controller.configuration.handle_exceptions # => false
    def self.duplicate(mod, controllers = 'Controllers', &blk)
      dupe.tap do |duplicated|
        mod.module_eval %{ module #{ controllers }; end } if controllers
        mod.module_eval %{ Action = Hanami::Action.dup }

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

