require 'lotus/utils/class'
require 'lotus/utils/kernel'
require 'lotus/utils/string'

module Lotus
  module Controller
    # Configuration for the framework, controllers and actions.
    #
    # Lotus::Controller has its own global configuration that can be manipulated
    # via `Lotus::Controller.configure`.
    #
    # Every time that `Lotus::Controller` and `Lotus::Action` are included, that
    # global configuration is being copied to the recipient. The copy will
    # inherit all the settings from the original, but all the subsequent changes
    # aren't reflected from the parent to the children, and viceversa.
    #
    # This architecture allows to have a global configuration that capture the
    # most common cases for an application, and let controllers and single
    # actions to specify exceptions.
    #
    # @since 0.2.0
    class Configuration
      # Default HTTP code for server side errors
      #
      # @since 0.2.0
      # @api private
      DEFAULT_ERROR_CODE = 500

      # Default Mime type to format mapping
      #
      # @since 0.2.0
      # @api private
      DEFAULT_FORMATS = {
        'application/octet-stream' => :all,
        '*/*'                      => :all,
        'text/html'                => :html
      }.freeze

      # Return a copy of the configuration of the framework instance associated
      # with the given class.
      #
      # When multiple instances of Lotus::Controller are used in the same
      # application, we want to make sure that a controller or an action will
      # receive the expected configuration.
      #
      # @param base [Class, Module] a controller or an action
      #
      # @return [Lotus::Controller::Configuration] the configuration associated
      #   to the given class.
      #
      # @since 0.2.0
      # @api private
      #
      # @example Direct usage of the framework
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #   end
      #
      #   Lotus::Controller::Configuration.for(Show)
      #     # => will duplicate from Lotus::Controller
      #
      # @example Multiple instances of the framework
      #   require 'lotus/controller'
      #
      #   module MyApp
      #     Controller = Lotus::Controller.duplicate(self)
      #
      #     module Controllers::Dashboard
      #       include MyApp::Controller
      #
      #       action 'Index' do
      #         def call(params)
      #           # ...
      #         end
      #       end
      #     end
      #   end
      #
      #   class Show
      #     include Lotus::Action
      #   end
      #
      #   Lotus::Controller::Configuration.for(Show)
      #     # => will duplicate from Lotus::Controller
      #
      #   Lotus::Controller::Configuration.for(MyApp::Controllers::Dashboard)
      #     # => will duplicate from MyApp::Controller
      def self.for(base)
        namespace = Utils::String.new(base).namespace
        framework = Utils::Class.load!("(#{namespace}|Lotus)::Controller")
        framework.configuration.duplicate
      end

      # Initialize a configuration instance
      #
      # @return [Lotus::Controller::Configuration] a new configuration's
      #   instance
      #
      # @since 0.2.0
      def initialize
        reset!
      end

      # @attr_writer handle_exceptions [TrueClass,FalseClass] Decide if handle
      #   exceptions with an HTTP status or not
      #
      # @since 0.2.0
      #
      # @see Lotus::Controller::Configuration#handle_exceptions
      attr_writer :handle_exceptions

      # Decide if handle exceptions with an HTTP status or let them uncaught
      #
      # If this value is set to `true`, the configured exceptions will return
      # the specified HTTP status, the rest of them with `500`.
      #
      # If this value is set to `false`, the exceptions won't be caught.
      #
      # This is part of a DSL, for this reason when this method is called with
      # an argument, it will set the corresponding instance variable. When
      # called without, it will return the already set value, or the default.
      #
      # @overload handle_exceptions(value)
      #   Sets the given value
      #   @param value [TrueClass, FalseClass] true or false, default to true
      #
      # @overload handle_exceptions
      #   Gets the value
      #   @return [TrueClass, FalseClass]
      #
      # @since 0.2.0
      #
      # @see Lotus::Controller::Configuration#handle_exception
      # @see Lotus::Controller#configure
      # @see Lotus::Action::Throwable
      # @see http://httpstatus.es/500
      #
      # @example Getting the value
      #   require 'lotus/controller'
      #
      #   Lotus::Controller.configuration.handle_exceptions # => true
      #
      # @example Setting the value
      #   require 'lotus/controller'
      #
      #   Lotus::Controller.configure do
      #     handle_exceptions false
      #   end
      def handle_exceptions(value = nil)
        if value.nil?
          @handle_exceptions
        else
          @handle_exceptions = value
        end
      end

      # Specify how to handle an exception with an HTTP status
      #
      # Raised exceptions will return the configured HTTP status, only if
      #   `handled_exceptions` is set on `true`.
      #
      # @param exception [Hash] the exception class must be the key and the HTTP
      #   status the value
      #
      # @since 0.2.0
      #
      # @see Lotus::Controller::Configuration#handle_exceptions
      # @see Lotus::Controller#configure
      # @see Lotus::Action::Throwable
      #
      # @example
      #   require 'lotus/controller'
      #
      #   Lotus::Controller.configure do
      #     handle_exception ArgumentError => 400
      #   end
      def handle_exception(exception)
        @handled_exceptions.merge!(exception)
      end

      # Return the HTTP status for the given exception
      #
      # Raised exceptions will return the configured HTTP status, only if
      #   `handled_exceptions` is set on `true`.
      #
      # @param exception [Hash] the exception class must be the key and the HTTP
      #   status the value of the hash
      #
      # @since 0.2.0
      # @api private
      #
      # @see Lotus::Controller::Configuration#handle_exception
      def exception_handler(exception)
        @handled_exceptions.fetch(exception) { DEFAULT_ERROR_CODE }
      end

      # Specify which is the default action module to be included when we use
      # the `Lotus::Controller.action` method.
      #
      # This setting is useful when we use multiple instances of the framework
      # in the same process, so we want to ensure that the actions will include
      # `MyApp::Action`, rather than `AnotherApp::Action`.
      #
      # If not set, the default value is `Lotus::Action`
      #
      # This is part of a DSL, for this reason when this method is called with
      # an argument, it will set the corresponding instance variable. When
      # called without, it will return the already set value, or the default.
      #
      # @overload action_module(value)
      #   Sets the given value
      #   @param value [Module] the module to be included in all the actions
      #
      # @overload action_module
      #   Gets the value
      #   @return [Module]
      #
      # @since 0.2.0
      #
      # @see Lotus::Controller::Dsl#action
      # @see Lotus::Controller#duplicate
      #
      # @example Getting the value
      #   require 'lotus/controller'
      #
      #   Lotus::Controller.configuration.action_module # => Lotus::Action
      #
      # @example Setting the value
      #   require 'lotus/controller'
      #
      #   module MyAction
      #   end
      #
      #   Lotus::Controller.configure do
      #     action_module MyAction
      #   end
      #
      #   class DashboardController
      #     include Lotus::Controller
      #
      #     # It includes MyAction, instead of Lotus::Action
      #     action 'Index' do
      #       def call(params)
      #         # ...
      #       end
      #     end
      #   end
      #
      # @example Duplicated framework
      #   require 'lotus/controller'
      #
      #   module MyApp
      #     Controller = Lotus::Controller.duplicate(self)
      #
      #     module Controllers::Dashboard
      #       include MyApp::Controller
      #
      #       # It includes MyApp::Action, instead of Lotus::Action
      #       action 'Index' do
      #         def call(params)
      #           # ...
      #         end
      #       end
      #     end
      #   end
      def action_module(value = nil)
        if value.nil?
          @action_module
        else
          @action_module = value
        end
      end

      # Specify the default modules to be included when `Lotus::Action` (or the
      # `action_module`) is included. This also works with
      # `Lotus::Controller.action`.
      #
      # If not set, this option will be ignored.
      #
      # This is part of a DSL, for this reason when this method is called with
      # an argument, it will set the corresponding instance variable. When
      # called without, it will return the already set value, or the default.
      #
      # @overload modules(blk)
      #   Adds the given block
      #   @param value [Proc] specify the modules to be included
      #
      # @overload modules
      #   Gets the value
      #   @return [Array] the list of the specified procs
      #
      # @since 0.2.0
      #
      # @see Lotus::Controller::Dsl#action
      # @see Lotus::Controller#duplicate
      #
      # @example Getting the value
      #   require 'lotus/controller'
      #
      #   Lotus::Controller.configuration.modules # => []
      #
      # @example Setting the value
      #   require 'lotus/controller'
      #   require 'lotus/action/cookies'
      #   require 'lotus/action/session'
      #
      #   Lotus::Controller.configure do
      #     modules do
      #       include Lotus::Action::Cookies
      #       include Lotus::Action::Session
      #     end
      #   end
      #
      #   class DashboardController
      #     include Lotus::Controller
      #
      #     # It includes:
      #     #   * Lotus::Action
      #     #   * Lotus::Action::Cookies
      #     #   * Lotus::Action::Session
      #     action 'Index' do
      #       def call(params)
      #         # ...
      #       end
      #     end
      #   end
      def modules(&blk)
        if block_given?
          @modules.push(blk)
        else
          @modules
        end
      end

      # Register a format
      #
      # @param hash [Hash] the symbol format must be the key and the mime type
      #   string must be the value of the hash
      #
      # @since 0.2.0
      #
      # @see Lotus::Action::Mime
      #
      # @example
      #   require 'lotus/controller'
      #
      #   Lotus::Controller.configure do
      #     format custom: 'application/custom'
      #   end
      #
      #   class ArticlesController
      #     include Lotus::Controller
      #
      #     action 'Index' do
      #       def call(params)
      #         # ...
      #       end
      #     end
      #
      #     action 'Show' do
      #       def call(params)
      #         # ...
      #         self.format = :custom
      #       end
      #     end
      #   end
      #
      #   action = ArticlesController::Index.new
      #
      #   action.call({ 'HTTP_ACCEPT' => 'text/html' })
      #     # => Content-Type "text/html"
      #   action.format # => :html
      #
      #   action.call({ 'HTTP_ACCEPT' => 'application/custom' })
      #     # => Content-Type "application/custom"
      #   action.format # => :custom
      #
      #
      #
      #   action = ArticlesController::Show.new
      #
      #   action.call({ 'HTTP_ACCEPT' => 'text/html' })
      #     # => Content-Type "application/custom"
      #   action.format # => :custom
      def format(hash)
        symbol, mime_type = *Utils::Kernel.Array(hash)

        @formats.merge! Utils::Kernel.String(mime_type) =>
          Utils::Kernel.Symbol(symbol)
      end

      # Set a format as default fallback for all the requests without a strict
      # requirement for the mime type.
      #
      # The given format must be coercible to a symbol, and be a valid mime type
      # alias. If it isn't, at the runtime the framework will raise a 
      # `Lotus::Controller::UnknownFormatError`.
      #
      # By default this value is nil.
      #
      # This is part of a DSL, for this reason when this method is called with
      # an argument, it will set the corresponding instance variable. When
      # called without, it will return the already set value, or the default.
      #
      # @overload default_format(format)
      #   Sets the given value
      #   @param format [#to_sym] the symbol format
      #   @raise [TypeError] if it cannot be coerced to a symbol
      #
      # @overload default_format
      #   Gets the value
      #   @return [Symbol,nil]
      #
      # @since 0.2.0
      #
      # @see Lotus::Action::Mime
      #
      # @example Getting the value
      #   require 'lotus/controller'
      #
      #   Lotus::Controller.configuration.default_format # => nil
      #
      # @example Setting the value
      #   require 'lotus/controller'
      #
      #   Lotus::Controller.configure do
      #     default_format :html
      #   end
      def default_format(format = nil)
        if format
          @default_format = Utils::Kernel.Symbol(format)
        else
          @default_format
        end
      end

      # Returns a format for the given mime type
      #
      # @param mime_type [#to_s,#to_str] A mime type
      #
      # @return [Symbol,nil] the corresponding format, if present
      #
      # @see Lotus::Controller::Configuration#format
      #
      # @since 0.2.0
      # @api private
      def format_for(mime_type)
        @formats[mime_type]
      end

      # Returns a mime type for the given format
      #
      # @param format [#to_sym] a format
      #
      # @return [String,nil] the corresponding mime type, if present
      def mime_type_for(format)
        @formats.key(format)
      end

      # Duplicate by copying the settings in a new instance.
      #
      # @return [Lotus::Controller::Configuration] a copy of the configuration
      #
      # @since 0.2.0
      # @api private
      def duplicate
        Configuration.new.tap do |c|
          c.handle_exceptions  = handle_exceptions
          c.handled_exceptions = handled_exceptions.dup
          c.action_module      = action_module
          c.modules            = modules.dup
          c.formats            = formats.dup
          c.default_format     = default_format
        end
      end

      # Reset all the values to the defaults
      #
      # @since 0.2.0
      # @api private
      def reset!
        @handle_exceptions  = true
        @handled_exceptions = {}
        @modules            = []
        @formats            = DEFAULT_FORMATS.dup
        @default_format     = nil
        @action_module      = ::Lotus::Action
      end

      # Load the configuration for the given action
      #
      # @since 0.2.0
      # @api private
      def load!(base)
        modules.each do |mod|
          base.class_eval(&mod)
        end
      end

      protected

      attr_accessor :handled_exceptions
      attr_accessor :formats
      attr_writer :action_module
      attr_writer :modules
      attr_writer :default_format
    end
  end
end
