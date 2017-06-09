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

      # Default public directory
      #
      # It serves as base root for file downloads
      #
      # @since 1.0.0
      # @api private
      DEFAULT_PUBLIC_DIRECTORY = 'public'.freeze

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
      def initialize(&blk)
        reset!
        instance_eval(&blk) unless blk.nil?
      end

      # Handle exceptions with an HTTP status or let them uncaught
      #
      # If this value is set to `true`, the configured exceptions will return
      # the specified HTTP status, the rest of them with `500`.
      #
      # If this value is set to `false`, the exceptions won't be caught.
      #
      # @attr_writer handle_exceptions [TrueClass,FalseClass] Handle exceptions
      #   with an HTTP status or leave them uncaught
      #
      # @attr_reader handle_exceptions [TrueClass,FalseClass] The result of the
      #   check
      #
      # @since 0.2.0
      #
      # @see Hanami::Controller::Configuration#handle_exception
      # @see Hanami::Controller#configure
      # @see Hanami::Action::Throwable
      # @see http://httpstatus.es/500
      #
      # FIXME: new API docs
      attr_accessor :handle_exceptions

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
      # @since 0.2.0
      #
      # @see Hanami::Controller::Dsl#action
      # @see Hanami::Controller#duplicate
      #
      # FIXME: new API docs
      attr_accessor :action_module

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
      #       include Hanami::Action::Session
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

        @formats[Utils::Kernel.String(mime_type)] = Utils::Kernel.Symbol(symbol)
        @mime_types = nil
      end

      # Return the configured format's MIME types
      #
      # @since 0.8.0
      # @api private
      #
      # @see Hanami::Controller::Configuration#format
      # @see Hanami::Action::Mime::MIME_TYPES
      def mime_types
        @mime_types ||= begin
                          ((@formats.keys - DEFAULT_FORMATS.keys) +
                          Hanami::Action::Mime::MIME_TYPES.values).freeze
                        end
      end

      # Restrict the MIME types set only to the given set
      #
      # @param mime_types [Array] the set of MIME types
      #
      # @since 1.0.0
      # @api private
      #
      # @see Hanami::Action::Mime::ClassMethods#accept
      def restrict_mime_types!(mime_types)
        @mime_types = self.mime_types & mime_types
      end

      def restrict_mime_types(mime_types)
        mime_types & self.mime_types
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
      # FIXME: new API docs
      def default_request_format=(value)
        @default_request_format = Utils::Kernel.Symbol(value) unless value.nil?
      end

      attr_reader :default_request_format

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
      # FIXME: new API docs
      def default_response_format=(value)
        @default_response_format = Utils::Kernel.Symbol(value) unless value.nil?
      end

      attr_reader :default_response_format

      # Set a charset as default fallback for all the requests without a strict
      # requirement for the charset.
      #
      # By default this value is nil.
      #
      # @since 0.3.0
      #
      # @see Hanami::Action::Mime
      #
      # FIXME: new API docs
      attr_accessor :default_charset

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

      # @api private
      # @since 1.0.0
      attr_reader :root_directory

      # FIXME: API docs
      def public_directory=(value)
        @public_directory = root_directory.join(value).to_s
      end

      attr_reader :public_directory

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
          c.public_directory        = public_directory
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
        @mime_types              = nil
        @default_request_format  = nil
        @default_response_format = nil
        @default_charset         = nil
        @default_headers         = {}
        @cookies                 = {}
        @root_directory          = ::Pathname.new(Dir.pwd).realpath
        @public_directory        = root_directory.join(DEFAULT_PUBLIC_DIRECTORY).to_s
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

      # FIXME turn into attr_reader
      attr_accessor :handled_exceptions

      protected

      attr_accessor :formats
      attr_writer :modules
      attr_writer :default_headers
      attr_writer :cookies
    end
  end
end
