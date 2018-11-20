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

      # Initialize a configuration instance
      #
      # @return [Hanami::Controller::Configuration] a new configuration's
      #   instance
      #
      # @since 0.2.0
      def initialize(&blk)
        @handled_exceptions      = {}
        @formats                 = DEFAULT_FORMATS.dup
        @mime_types              = nil
        @default_request_format  = nil
        @default_response_format = nil
        @default_charset         = nil
        @default_headers         = {}
        @cookies                 = {}
        @root_directory          = ::Pathname.new(Dir.pwd).realpath
        @public_directory        = root_directory.join(DEFAULT_PUBLIC_DIRECTORY).to_s
        instance_eval(&blk) unless blk.nil?
        freeze
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
      end

      # Return the configured format's MIME types
      #
      # @since 0.8.0
      # @api private
      #
      # @see Hanami::Controller::Configuration#format
      def mime_types
        # FIXME: this isn't efficient. speed it up!
        ((@formats.keys - DEFAULT_FORMATS.keys) +
         Hanami::Action::Mime::TYPES.values).freeze
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

      attr_reader :cookies

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
      #   Hanami::Controller::Configuration.new do |config|
      #     config.cookies = {
      #       domain: 'hanamirb.org',
      #       path: '/controller',
      #       secure: true,
      #       httponly: true
      #     }
      #   end
      def cookies=(options)
        @cookies.merge!(
          options.reject { |_, v| v.nil? }
        )
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
      attr_reader :handled_exceptions
    end
  end
end
