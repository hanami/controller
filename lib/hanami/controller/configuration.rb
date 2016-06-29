require 'hanami/utils/class'
require 'hanami/utils/kernel'
require 'hanami/utils/string'

require 'hanami/configuration'

module Hanami
  module Controller
    # Configuration for the framework, controllers and actions.
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
    class Configuration < Hanami::Configuration
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

      setting :handled_exceptions, {}
      setting :modules,            []
      setting :formats,            DEFAULT_FORMATS.dup
      setting :action_module,      ::Hanami::Action

      # Handle exceptions with an HTTP status or let them uncaught
      #
      # If this value is set to `true`, the configured exceptions will return
      # the specified HTTP status, the rest of them with `500`.
      #
      # If this value is set to `false`, the exceptions won't be caught.
      #
      # @since 0.2.0
      #
      # @see Hanami::Controller::Configuration#handle_exception
      # @see Hanami::Action::Throwable
      # @see http://httpstatus.es/500
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     class MyAction
      #       include Hanami::Action
      #     end
      #   end
      #
      #   Controllers.configuration.handle_exceptions           # => true
      #   Controllers::MyAction.configuration.handle_exceptions # => true
      #
      # @example Setting the value for all the actions in an application
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     configure do |config|
      #       config.handle_exceptions = false
      #     end
      #
      #     class MyAction
      #       include Hanami::Action
      #     end
      #   end
      #
      #   Controllers.configuration.handle_exceptions           # => false
      #   Controllers::MyAction.configuration.handle_exceptions # => false
      #
      # @example Setting the value for an action
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     class MyAction
      #       include Hanami::Action
      #
      #       configure do |config|
      #         config.handle_exceptions = false
      #       end
      #     end
      #   end
      #
      #   Controllers.configuration.handle_exceptions           # => true
      #   Controllers::MyAction.configuration.handle_exceptions # => false
      setting :handle_exceptions, true

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
        handled_exceptions.merge!(exception)
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

        handled_exceptions.each do |exception_class, h|
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
          !!handled_exceptions.fetch(exception.class) { false }
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
          duplicate do |c|
            c.modules.push(blk)
          end
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

        formats.merge! Utils::Kernel.String(mime_type) =>
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
      # @since 0.5.0
      #
      # @see Hanami::Action::Mime
      #
      # @example Get the value
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     class MyAction
      #       include Hanami::Action
      #     end
      #   end
      #
      #   Controllers.configuration.default_request_format           # => nil
      #   Controllers::MyAction.configuration.default_request_format # => nil
      #
      # @example Set the value for all the actions of an application
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     configure do |config|
      #       config.default_request_format = :html
      #     end
      #
      #     class MyAction
      #       include Hanami::Action
      #     end
      #   end
      #
      #   Controllers.configuration.default_request_format           # => :html
      #   Controllers::MyAction.configuration.default_request_format # => :html
      #
      # @example Set the value for an action
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     class MyAction
      #       include Hanami::Action
      #
      #       configure do |config|
      #         config.default_request_format = :html
      #       end
      #     end
      #   end
      #
      #   Controllers.configuration.default_request_format           # => nil
      #   Controllers::MyAction.configuration.default_request_format # => :html
      setting :default_request_format, nil, writer: false

      # @since x.x.x
      def default_request_format=(value)
        settings[:default_request_format] = Utils::Kernel.Symbol(value)
      end

      # Set a format to be used for all responses regardless of the request type.
      #
      # The given format must be coercible to a symbol, and be a valid mime type
      # alias. If it isn't, at the runtime the framework will raise a
      # `Hanami::Controller::UnknownFormatError`.
      #
      # By default this value is nil.
      #
      # @since 0.5.0
      #
      # @see Hanami::Action::Mime
      #
      # @example Get the value
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     class MyAction
      #       include Hanami::Action
      #     end
      #   end
      #
      #   Controllers.configuration.default_response_format           # => nil
      #   Controllers::MyAction.configuration.default_response_format # => nil
      #
      # @example Set the value for all the actions of an application
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     configure do |config|
      #       config.default_response_format = :html
      #     end
      #
      #     class MyAction
      #       include Hanami::Action
      #     end
      #   end
      #
      #   Controllers.configuration.default_response_format           # => :html
      #   Controllers::MyAction.configuration.default_response_format # => :html
      #
      # @example Set the value for an action
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     class MyAction
      #       include Hanami::Action
      #
      #       configure do |config|
      #         config.default_response_format = :html
      #       end
      #     end
      #   end
      #
      #   Controllers.configuration.default_response_format           # => nil
      #   Controllers::MyAction.configuration.default_response_format # => :html
      setting :default_response_format, nil, writer: false

      # @since x.x.x
      def default_response_format=(value)
        settings[:default_response_format] = Utils::Kernel.Symbol(value)
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
      # @example Get the value
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     class MyAction
      #       include Hanami::Action
      #     end
      #   end
      #
      #   Controllers.configuration.default_charset           # => nil
      #   Controllers::MyAction.configuration.default_charset # => nil
      #
      # @example Set the value for all the actions of an application
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     configure do |config|
      #       config.default_charset = 'utf-8'
      #     end
      #
      #     class MyAction
      #       include Hanami::Action
      #     end
      #   end
      #
      #   Controllers.configuration.default_charset           # => "utf-8"
      #   Controllers::MyAction.configuration.default_charset # => "utf-8"
      #
      # @example Set the value for an action
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     class MyAction
      #       include Hanami::Action
      #
      #       configure do |config|
      #         config.default_charset = 'utf-8'
      #       end
      #     end
      #   end
      #
      #   Controllers.configuration.default_charset           # => nil
      #   Controllers::MyAction.configuration.default_charset # => "utf-8"
      setting :default_charset, nil

      # Set default cookies options for all responses
      #
      # By default this value is an empty hash.
      #
      # @since 0.4.0
      #
      # @example Get the value
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #   end
      #
      #   Controllers.configuration.cookies # => {}
      #
      # @example Set the value
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     configure do |config|
      #       config.cookies(
      #         domain: 'hanamirb.org',
      #         path: '/controller',
      #         secure: true,
      #         httponly: true
      #       )
      #     end
      #   end
      setting :cookies, {}, reader: false

      # @since 0.4.0
      def cookies(options = nil)
        if !options.nil?
          duplicate do |c|
            c.settings[:cookies].merge!(
              options.reject { |_, v| v.nil? }
            )
          end
        else
          settings[:cookies]
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
        formats[mime_type]
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
        formats.key(format)
      end

      # Set default headers for all responses
      #
      # By default this value is an empty hash.
      #
      # @since 0.4.0
      #
      # @example Get the value
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #   end
      #
      #   Controllers.configuration.default_headers # => {}
      #
      # @example Set the value
      #   require 'hanami/controller'
      #
      #   module Controllers
      #     include Hanami::Controller
      #
      #     configure do |config|
      #       config.default_headers(
      #         'X-Frame-Options' => 'DENY'
      #       )
      #     end
      #   end
      setting :default_headers, {}, reader: false

      # @since 0.4.0
      def default_headers(headers = nil)
        if !headers.nil?
          duplicate do |c|
            c.settings[:default_headers].merge!(
              headers.reject { |_, v| v.nil? }
            )
          end
        else
          settings[:default_headers]
        end
      end

      # @api private
      def copy!(base)
        modules.each do |mod|
          base.class_eval(&mod)
        end
      end

      protected

      # @since 0.5.0
      # @api private
      def _sort_handled_exceptions!
        handled_exceptions.replace Hash[
          handled_exceptions.sort { |(ex1, _), (ex2, _)| ex1.ancestors.include?(ex2) ? -1 : 1 }
        ]
      end
    end
  end
end
