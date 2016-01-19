require 'hanami/utils/class'
require 'hanami/utils/kernel'
require 'hanami/utils/string'

module Hanami
  module Controller
    # Configuration for the framework, controllers and actions.
    #
    # Hanami::Controller has its own global configuration that can be manipulated
    # via `Hanami::Controller.configure`.
    #
    # Every time that `Hanami::Controller` and `Hanami::Action` are included, that
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
      # When multiple instances of Hanami::Controller are used in the same
      # application, we want to make sure that a controller or an action will
      # receive the expected configuration.
      #
      # @param base [Class, Module] a controller or an action
      #
      # @return [Hanami::Controller::Configuration] the configuration associated
      #   to the given class.
      #
      # @since 0.2.0
      # @api private
      #
      # @example Direct usage of the framework
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #   end
      #
      #   Hanami::Controller::Configuration.for(Show)
      #     # => will duplicate from Hanami::Controller
      #
      # @example Multiple instances of the framework
      #   require 'hanami/controller'
      #
      #   module MyApp
      #     Controller = Hanami::Controller.duplicate(self)
      #
      #     module Controllers::Dashboard
      #       class Index
      #         include MyApp::Action
      #
      #         def call(params)
      #           # ...
      #         end
      #       end
      #     end
      #   end
      #
      #   class Show
      #     include Hanami::Action
      #   end
      #
      #   Hanami::Controller::Configuration.for(Show)
      #     # => will duplicate from Hanami::Controller
      #
      #   Hanami::Controller::Configuration.for(MyApp::Controllers::Dashboard)
      #     # => will duplicate from MyApp::Controller
      def self.for(base)
        namespace = Utils::String.new(base).namespace
        framework = Utils::Class.load_from_pattern!("(#{namespace}|Hanami)::Controller")
        framework.configuration.duplicate
      end

      # Initialize a configuration instance
      #
      # @return [Hanami::Controller::Configuration] a new configuration's
      #   instance
      #
      # @since 0.2.0
      def initialize
        reset!
      end

      # @attr_writer handle_exceptions [TrueClass,FalseClass] Handle exceptions
      #   with an HTTP status or leave them uncaught
      #
      # @since 0.2.0
      #
      # @return void
      #
      # @see Hanami::Controller::Configuration#handle_exceptions
      attr_writer :handle_exceptions

      # Handle exceptions with an HTTP status or let them uncaught
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
      # @see Hanami::Controller::Configuration#handle_exception
      # @see Hanami::Controller#configure
      # @see Hanami::Action::Throwable
      # @see http://httpstatus.es/500
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configuration.handle_exceptions # => true
      #
      # @example Setting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
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
      # @see Hanami::Controller::Configuration#handle_exceptions
      # @see Hanami::Controller#configure
      # @see Hanami::Action::Throwable
      #
      # @example
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     handle_exception ArgumentError => 400
      #   end
      def handle_exception(exception)
        @handled_exceptions.merge!(exception)
        _sort_handled_exceptions!
      end

      # Return a callable handler for the given exception
      #
      # @param exception [Exception] an exception
      #
      # @since 0.3.0
      # @api private
      #
      # @see Hanami::Controller::Configuration#handle_exception
      def exception_handler(exception)
        handler = nil

        @handled_exceptions.each do |exception_class, h|
          if exception.kind_of?(exception_class)
            handler = h
            break
          end
        end

        handler || DEFAULT_ERROR_CODE
      end

      # Check if the given exception is handled.
      #
      # @param exception [Exception] an exception
      #
      # @since 0.3.2
      # @api private
      #
      # @see Hanami::Controller::Configuration#handle_exception
      def handled_exception?(exception)
        handled_exceptions &&
          !!@handled_exceptions.fetch(exception.class) { false }
      end

      # Specify which is the default action module to be included when we use
      # the `Hanami::Controller.action` method.
      #
      # This setting is useful when we use multiple instances of the framework
      # in the same process, so we want to ensure that the actions will include
      # `MyApp::Action`, rather than `AnotherApp::Action`.
      #
      # If not set, the default value is `Hanami::Action`
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
      # @see Hanami::Controller::Dsl#action
      # @see Hanami::Controller#duplicate
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configuration.action_module # => Hanami::Action
      #
      # @example Setting the value
      #   require 'hanami/controller'
      #
      #   module MyAction
      #   end
      #
      #   Hanami::Controller.configure do
      #     action_module MyAction
      #   end
      #
      #   module Dashboard
      #     # It includes MyAction, instead of Hanami::Action
      #     class Index
      #       include MyAction
      #
      #       def call(params)
      #         # ...
      #       end
      #     end
      #   end
      #
      # @example Duplicated framework
      #   require 'hanami/controller'
      #
      #   module MyApp
      #     Controller = Hanami::Controller.duplicate(self)
      #
      #     module Controllers::Dashboard
      #       include MyApp::Controller
      #
      #       # It includes MyApp::Action, instead of Hanami::Action
      #       class Index
      #         include MyApp::Action
      #
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

      # Configure the logic to be executed when Hanami::Action is included
      # This is useful to DRY code by having a single place where to configure
      # shared behaviors like authentication, sessions, cookies etc.
      #
      # This method can be called multiple times.
      #
      # @param blk [Proc] the code block
      #
      # @return [void]
      #
      # @raise [ArgumentError] if called without passing a block
      #
      # @since 0.3.0
      #
      # @see Hanami::Controller.configure
      # @see Hanami::Controller.duplicate
      #
      # @example Configure shared logic.
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     prepare do
      #       include Hanami::Action::Sessions
      #       include MyAuthentication
      #       use SomeMiddleWare
      #
      #       before { authenticate! }
      #     end
      #   end
      #
      #   module Dashboard
      #     class Index
      #       # When Hanami::Action is included, it will:
      #       #   * Include `Hanami::Action::Session` and `MyAuthentication`
      #       #   * Configure to use `SomeMiddleWare`
      #       #   * Configure a `before` callback that triggers `#authenticate!`
      #       include Hanami::Action
      #
      #       def call(params)
      #         # ...
      #       end
      #     end
      #   end
      def prepare(&blk)
        if block_given?
          @modules.push(blk)
        else
          raise ArgumentError.new('Please provide a block')
        end
      end

      # Register a format
      #
      # @param hash [Hash] the symbol format must be the key and the mime type
      #   string must be the value of the hash
      #
      # @since 0.2.0
      #
      # @see Hanami::Action::Mime
      #
      # @example
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     format custom: 'application/custom'
      #   end
      #
      #   module Articles
      #     class Index
      #       include Hanami::Action
      #
      #       def call(params)
      #         # ...
      #       end
      #     end
      #
      #     class Show
      #       include Hanami::Action
      #
      #       def call(params)
      #         # ...
      #         self.format = :custom
      #       end
      #     end
      #   end
      #
      #   action = Articles::Index.new
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
      #   action = Articles::Show.new
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
      # `Hanami::Controller::UnknownFormatError`.
      #
      # By default this value is nil.
      #
      # This is part of a DSL, for this reason when this method is called with
      # an argument, it will set the corresponding instance variable. When
      # called without, it will return the already set value, or the default.
      #
      # @overload default_request_format(format)
      #   Sets the given value
      #   @param format [#to_sym] the symbol format
      #   @raise [TypeError] if it cannot be coerced to a symbol
      #
      # @overload default_request_format
      #   Gets the value
      #   @return [Symbol,nil]
      #
      # @since 0.5.0
      #
      # @see Hanami::Action::Mime
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configuration.default_request_format # => nil
      #
      # @example Setting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     default_request_format :html
      #   end
      def default_request_format(format = nil)
        if format
          @default_request_format = Utils::Kernel.Symbol(format)
        else
          @default_request_format
        end
      end

      # Set a format to be used for all responses regardless of the request type.
      #
      # The given format must be coercible to a symbol, and be a valid mime type
      # alias. If it isn't, at the runtime the framework will raise a
      # `Hanami::Controller::UnknownFormatError`.
      #
      # By default this value is nil.
      #
      # This is part of a DSL, for this reason when this method is called with
      # an argument, it will set the corresponding instance variable. When
      # called without, it will return the already set value, or the default.
      #
      # @overload default_response_format(format)
      #   Sets the given value
      #   @param format [#to_sym] the symbol format
      #   @raise [TypeError] if it cannot be coerced to a symbol
      #
      # @overload default_response_format
      #   Gets the value
      #   @return [Symbol,nil]
      #
      # @since 0.5.0
      #
      # @see Hanami::Action::Mime
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configuration.default_response_format # => nil
      #
      # @example Setting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     default_response_format :json
      #   end
      def default_response_format(format = nil)
        if format
          @default_response_format = Utils::Kernel.Symbol(format)
        else
          @default_response_format
        end
      end

      # Set a charset as default fallback for all the requests without a strict
      # requirement for the charset.
      #
      # By default this value is nil.
      #
      # @since 0.3.0
      #
      # @see Hanami::Action::Mime
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configuration.default_charset # => nil
      #
      # @example Setting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     default_charset 'koi8-r'
      #   end
      def default_charset(charset = nil)
        if charset
          @default_charset = charset
        else
          @default_charset
        end
      end

      # Set default headers for all responses
      #
      # By default this value is an empty hash.
      #
      # @since 0.4.0
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configuration.default_headers # => {}
      #
      # @example Setting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     default_headers({
      #       'X-Frame-Options' => 'DENY'
      #     })
      #   end
      def default_headers(headers = nil)
        if headers
          @default_headers.merge!(
            headers.reject {|_,v| v.nil? }
          )
        else
          @default_headers
        end
      end

      # Set default cookies options for all responses
      #
      # By default this value is an empty hash.
      #
      # @since 0.4.0
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configuration.cookies # => {}
      #
      # @example Setting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     cookies({
      #       domain: 'hanamirb.org',
      #       path: '/controller',
      #       secure: true,
      #       httponly: true
      #     })
      #   end
      def cookies(options = nil)
        if options
          @cookies.merge!(
            options.reject { |_, v| v.nil? }
          )
        else
          @cookies
        end
      end

      # Returns a format for the given mime type
      #
      # @param mime_type [#to_s,#to_str] A mime type
      #
      # @return [Symbol,nil] the corresponding format, if present
      #
      # @see Hanami::Controller::Configuration#format
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
      #
      # @since 0.2.0
      # @api private
      def mime_type_for(format)
        @formats.key(format)
      end

      # Duplicate by copying the settings in a new instance.
      #
      # @return [Hanami::Controller::Configuration] a copy of the configuration
      #
      # @since 0.2.0
      # @api private
      def duplicate
        Configuration.new.tap do |c|
          c.handle_exceptions       = handle_exceptions
          c.handled_exceptions      = handled_exceptions.dup
          c.action_module           = action_module
          c.modules                 = modules.dup
          c.formats                 = formats.dup
          c.default_request_format  = default_request_format
          c.default_response_format = default_response_format
          c.default_charset         = default_charset
          c.default_headers         = default_headers.dup
          c.cookies = cookies.dup
        end
      end

      # Return included modules
      #
      # @return [Array<Proc>] array of included blocks
      #
      # @since 0.2.0
      # @api private
      #
      # @see Hanami::Controller::Configuration#prepare
      attr_reader :modules

      # Reset all the values to the defaults
      #
      # @since 0.2.0
      # @api private
      def reset!
        @handle_exceptions       = true
        @handled_exceptions      = {}
        @modules                 = []
        @formats                 = DEFAULT_FORMATS.dup
        @default_request_format  = nil
        @default_response_format = nil
        @default_charset         = nil
        @default_headers         = {}
        @cookies                 = {}
        @action_module           = ::Hanami::Action
      end

      # Copy the configuration for the given action
      #
      # @param base [Class] the target action
      #
      # @return void
      #
      # @since 0.3.0
      # @api private
      #
      # @see Hanami::Controller::Configurable.included
      def copy!(base)
        modules.each do |mod|
          base.class_eval(&mod)
        end
      end

      # Load the framework
      #
      # @since 0.3.0
      # @api private
      def load!
        freeze
      end

      protected
      # @since 0.5.0
      # @api private
      def _sort_handled_exceptions!
        @handled_exceptions = Hash[
          @handled_exceptions.sort{|(ex1,_),(ex2,_)| ex1.ancestors.include?(ex2) ? -1 : 1 }
        ]
      end

      attr_accessor :handled_exceptions
      attr_accessor :formats
      attr_writer :action_module
      attr_writer :modules
      attr_writer :default_request_format
      attr_writer :default_response_format
      attr_writer :default_charset
      attr_writer :default_headers
      attr_writer :cookies
    end
  end
end
