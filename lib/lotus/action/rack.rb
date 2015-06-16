require 'securerandom'
require 'lotus/action/request'
require 'lotus/action/rack/callable'
require 'lotus/action/rack/file'

module Lotus
  module Action
    # Rack integration API
    #
    # @since 0.1.0
    module Rack
      # The default HTTP response code
      #
      # @since 0.1.0
      # @api private
      DEFAULT_RESPONSE_CODE = 200

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
      # @see Lotus::Action::Rack#request_id
      DEFAULT_REQUEST_ID_LENGTH = 16

      # The request method
      #
      # @since 0.3.2
      # @api private
      REQUEST_METHOD = 'REQUEST_METHOD'.freeze

      # HEAD request
      #
      # @since 0.3.2
      # @api private
      HEAD = 'HEAD'.freeze

      # Override Ruby's hook for modules.
      # It includes basic Lotus::Action modules to the given class.
      #
      # @param base [Class] the target action
      #
      # @since 0.1.0
      # @api private
      #
      # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Build rack builder
        #
        # @return [Rack::Builder]
        def rack_builder
          @rack_builder ||= begin
            extend Lotus::Action::Rack::Callable
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
        # @see Lotus::Action::Callbacks::ClassMethods#before
        #
        # @example Middleware
        #   require 'lotus/controller'
        #
        #   module Sessions
        #     class Create
        #       include Lotus::Action
        #       use OmniAuth
        #
        #       def call(params)
        #         # ...
        #       end
        #     end
        #   end
        def use(middleware, *args, &block)
          rack_builder.use middleware, *args, &block
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
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
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
      # @see Lotus::Action::Rack::DEFAULT_RESPONSE_CODE
      # @see Lotus::Action::Rack::DEFAULT_RESPONSE_BODY
      # @see Lotus::Action::Rack#status=
      # @see Lotus::Action::Rack#headers
      # @see Lotus::Action::Rack#body=
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

      # Returns a Lotus specialized rack request
      #
      # @return [Lotus::Action::Request] The request
      #
      # @since 0.3.1
      #
      # @example
      #   require 'lotus/controller'
      #
      #   class Create
      #     include Lotus::Action
      #
      #     def call(params)
      #       ip     = request.ip
      #       secure = request.ssl?
      #     end
      #   end
      def request
        @request ||= ::Lotus::Action::Request.new(@_env)
      end

      private

      # Sets the HTTP status code for the response
      #
      # @param status [Fixnum] an HTTP status code
      # @return [void]
      #
      # @since 0.1.0
      #
      # @example
      #   require 'lotus/controller'
      #
      #   class Create
      #     include Lotus::Action
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
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
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
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       send_file Pathname.new('path/to/file')
      #     end
      #   end
      def send_file(path)
        result = File.new(path).call(@_env)
        headers.merge!(result[1])
        halt result[0], result[2]
      end

      # Check if the current request is a HEAD
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.3.2
      def head?
        request_method == HEAD
      end

      # NOTE: <tt>Lotus::Action::CSRFProtection</tt> (<tt>lotusrb</tt> gem) depends on this.
      #
      # @api private
      # @since 0.4.4
      def request_method
        @_env[REQUEST_METHOD]
      end
    end
  end
end
