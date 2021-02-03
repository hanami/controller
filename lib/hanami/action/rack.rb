require 'securerandom'
require 'hanami/action/request'
require 'hanami/action/base_params'
require 'hanami/action/rack/callable'
require 'hanami/action/rack/file'
require 'hanami/utils/deprecation'

module Hanami
  module Action
    # Rack integration API
    #
    # @since 0.1.0
    module Rack
      # Rack SPEC response code
      #
      # @since 1.0.0
      # @api private
      RESPONSE_CODE = 0

      # Rack SPEC response headers
      #
      # @since 1.0.0
      # @api private
      RESPONSE_HEADERS = 1

      # Rack SPEC response body
      #
      # @since 1.0.0
      # @api private
      RESPONSE_BODY = 2

      # The default HTTP response code
      #
      # @since 0.1.0
      # @api private
      DEFAULT_RESPONSE_CODE = 200

      # Not Found
      #
      # @since 1.0.0
      # @api private
      NOT_FOUND = 404

      # The default Rack response body
      #
      # @since 0.1.0
      # @api private
      DEFAULT_RESPONSE_BODY = []

      # The default HTTP Request ID length
      #
      # @since 0.3.0
      # @api private
      #
      # @see Hanami::Action::Rack#request_id
      DEFAULT_REQUEST_ID_LENGTH = 16

      # The request method
      #
      # @since 0.3.2
      # @api private
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze

      # The Content-Length HTTP header
      #
      # @since 1.0.0
      # @api private
      CONTENT_LENGTH = 'Content-Length'.freeze

      # The non-standard HTTP header to pass the control over when a resource
      # cannot be found by the current endpoint
      #
      # @since 1.0.0
      # @api private
      X_CASCADE = 'X-Cascade'.freeze

      # HEAD request
      #
      # @since 0.3.2
      # @api private
      HEAD = 'HEAD'.freeze

      # The key that returns router parsed body from the Rack env
      ROUTER_PARSED_BODY = 'router.parsed_body'.freeze

      # This is the root directory for `#unsafe_send_file`
      #
      # @since 1.3.3
      # @api private
      #
      # @see #unsafe_send_file
      FILE_SYSTEM_ROOT = Pathname.new("/").freeze

      # Override Ruby's hook for modules.
      # It includes basic Hanami::Action modules to the given class.
      #
      # @param base [Class] the target action
      #
      # @since 0.1.0
      # @api private
      #
      # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
      def self.included(base)
        base.class_eval do
          extend ClassMethods
          prepend InstanceMethods
        end
      end

      # @api private
      module ClassMethods
        # Build rack builder
        #
        # @return [Rack::Builder]
        # @api private
        def rack_builder
          @rack_builder ||= begin
            extend Hanami::Action::Rack::Callable
            rack_builder = ::Rack::Builder.new
            rack_builder.run ->(env) { self.new.call(env) }
            rack_builder
          end
        end

        # Use a Rack middleware
        #
        # The middleware will be used as it is.
        #
        # At the runtime, the middleware be invoked with the raw Rack env.
        #
        # Multiple middlewares can be employed, just by using multiple times
        # this method.
        #
        # @param middleware [#call] A Rack middleware
        # @param args [Array] Array arguments for middleware
        #
        # @since 0.2.0
        #
        # @see Hanami::Action::Callbacks::ClassMethods#before
        #
        # @example Middleware
        #   require 'hanami/controller'
        #
        #   module Sessions
        #     class Create
        #       include Hanami::Action
        #       use OmniAuth
        #
        #       def call(params)
        #         # ...
        #       end
        #     end
        #   end
        if RUBY_VERSION >= '3.0'
          def use(middleware, *args, **kwargs, &block)
            rack_builder.use middleware, *args, **kwargs, &block
          end
        else
          def use(middleware, *args, &block)
            rack_builder.use middleware, *args, &block
          end
        end

        # Returns the class which defines the params
        #
        # Returns the class which has been provided to define the
        # params. By default this will be Hanami::Action::Params.
        #
        # @return [Class] A params class (when whitelisted) or
        #   Hanami::Action::Params
        #
        # @api private
        # @since 0.7.0
        def params_class
          @params_class ||= BaseParams
        end
      end

      # @since 0.7.0
      # @api private
      module InstanceMethods
        # @since 0.7.0
        # @api private
        if RUBY_VERSION >= '3.0'
          def initialize(*, **)
            super
            @_status = nil
            @_body   = nil
          end
        else
          def initialize(*)
            super
            @_status = nil
            @_body   = nil
          end
        end
      end

      protected
      # Gets the headers from the response
      #
      # @return [Hash] the HTTP headers from the response
      #
      # @since 0.1.0
      #
      # @example
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #
      #     def call(params)
      #       # ...
      #       self.headers            # => { ... }
      #       self.headers.merge!({'X-Custom' => 'OK'})
      #     end
      #   end
      def headers
        @headers
      end

      # Returns a serialized Rack response (Array), according to the current
      #   status code, headers, and body.
      #
      # @return [Array] the serialized response
      #
      # @since 0.1.0
      # @api private
      #
      # @see Hanami::Action::Rack::DEFAULT_RESPONSE_CODE
      # @see Hanami::Action::Rack::DEFAULT_RESPONSE_BODY
      # @see Hanami::Action::Rack#status=
      # @see Hanami::Action::Rack#headers
      # @see Hanami::Action::Rack#body=
      def response
        [ @_status || DEFAULT_RESPONSE_CODE, headers, @_body || DEFAULT_RESPONSE_BODY.dup ]
      end

      # Calculates an unique ID for the current request
      #
      # @return [String] The unique ID
      #
      # @since 0.3.0
      def request_id
        # FIXME make this number configurable and document the probabilities of clashes
        @request_id ||= SecureRandom.hex(DEFAULT_REQUEST_ID_LENGTH)
      end

      # Returns a Hanami specialized rack request
      #
      # @return [Hanami::Action::Request] The request
      #
      # @since 0.3.1
      #
      # @example
      #   require 'hanami/controller'
      #
      #   class Create
      #     include Hanami::Action
      #
      #     def call(params)
      #       ip     = request.ip
      #       secure = request.ssl?
      #     end
      #   end
      def request
        @request ||= ::Hanami::Action::Request.new(@_env)
      end

      # Return parsed request body
      #
      # @deprecated
      def parsed_request_body
        Hanami::Utils::Deprecation.new('#parsed_request_body is deprecated and it will be removed in future versions')
        @_env.fetch(ROUTER_PARSED_BODY, nil)
      end

      private

      # Sets the HTTP status code for the response
      #
      # @param status [Integer] an HTTP status code
      # @return [void]
      #
      # @since 0.1.0
      #
      # @example
      #   require 'hanami/controller'
      #
      #   class Create
      #     include Hanami::Action
      #
      #     def call(params)
      #       # ...
      #       self.status = 201
      #     end
      #   end
      def status=(status)
        @_status = status
      end

      # Sets the body of the response
      #
      # @param body [String] the body of the response
      # @return [void]
      #
      # @since 0.1.0
      #
      # @example
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #
      #     def call(params)
      #       # ...
      #       self.body = 'Hi!'
      #     end
      #   end
      def body=(body)
        body   = Array(body) unless body.respond_to?(:each)
        @_body = body
      end

      # Send a file as response.
      #  <tt>This method only sends files from the public directory</tt>
      #
      # It automatically handle the following cases:
      #
      #   * <tt>Content-Type</tt> and <tt>Content-Length</tt>
      #   * File Not found (returns a 404)
      #   * Conditional GET (via <tt>If-Modified-Since</tt> header)
      #   * Range requests (via <tt>Range</tt> header)
      #
      # @param path [String, Pathname] the body of the response
      # @return [void]
      #
      # @since 0.4.3
      #
      # @example
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #
      #     def call(params)
      #       # ...
      #       send_file Pathname.new('path/to/file')
      #     end
      #   end
      def send_file(path)
        _send_file(
          File.new(path, self.class.configuration.public_directory).call(@_env)
        )
      end

      # Send a file as response from anywhere in the file system.
      #
      # @see Hanami::Action::Rack#send_file
      #
      # @param path [String, Pathname] path to the file to be sent
      # @return [void]
      #
      # @since 1.0.0
      #
      # @example
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #
      #     def call(params)
      #       # ...
      #       unsafe_send_file Pathname.new('/tmp/path/to/file')
      #     end
      #   end
      def unsafe_send_file(path)
        directory = if Pathname.new(path).relative?
                      self.class.configuration.root_directory
                    else
                      FILE_SYSTEM_ROOT
                    end

        _send_file(
          File.new(path, directory).call(@_env)
        )
      end

      # Check if the current request is a HEAD
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.3.2
      def head?
        request_method == HEAD
      end

      # NOTE: <tt>Hanami::Action::CSRFProtection</tt> (<tt>hanamirb</tt> gem) depends on this.
      #
      # @api private
      # @since 0.4.4
      def request_method
        @_env[REQUEST_METHOD]
      end

      # @since 1.0.0
      # @api private
      def _send_file(response)
        headers.merge!(response[RESPONSE_HEADERS])

        if response[RESPONSE_CODE] == NOT_FOUND
          headers.delete(X_CASCADE)
          headers.delete(CONTENT_LENGTH)
          halt NOT_FOUND
        else
          # FIXME: this is a fix for https://github.com/hanami/controller/issues/240
          # It's here to maintain the backward compat with 1.1, as we can't remove `#halt`
          # We should review the workflow for 2.0, because I don't like callbacks to be referenced from here.
          _run_after_callbacks(params)
          halt response[RESPONSE_CODE], response[RESPONSE_BODY]
        end
      end
    end
  end
end
