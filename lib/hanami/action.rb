begin
  require 'hanami/validations'
  require 'hanami/action/validatable'
rescue LoadError
end

require 'hanami/action/request'
require 'hanami/action/response'
require 'hanami/action/base_params'
require 'hanami/action/rack/file'

require 'rack/utils'
require 'hanami/utils'
require 'hanami/utils/kernel'

require 'hanami/utils/class_attribute'
require 'hanami/http/status'

require 'hanami/utils/callbacks'

module Hanami
  # An HTTP endpoint
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
  #     end
  #   end
  class Action
    require "hanami/action/mime"

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

    DEFAULT_ERROR_CODE = 500

    # Status codes that by RFC must not include a message body
    #
    # @since 0.3.2
    # @api private
    HTTP_STATUSES_WITHOUT_BODY = Set.new((100..199).to_a << 204 << 205 << 304).freeze

    # Not Found
    #
    # @since 1.0.0
    # @api private
    NOT_FOUND = 404

    # Entity headers allowed in blank body responses, according to
    # RFC 2616 - Section 10 (HTTP 1.1).
    #
    # "The response MAY include new or updated metainformation in the form
    #   of entity-headers".
    #
    # @since 0.4.0
    # @api private
    #
    # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5
    # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec7.html
    ENTITY_HEADERS = {
      'Allow'            => true,
      'Content-Encoding' => true,
      'Content-Language' => true,
      'Content-Location' => true,
      'Content-MD5'      => true,
      'Content-Range'    => true,
      'Expires'          => true,
      'Last-Modified'    => true,
      'extension-header' => true
    }.freeze

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

    # The key that returns accepted mime types from the Rack env
    #
    # @since 0.1.0
    # @api private
    HTTP_ACCEPT          = 'HTTP_ACCEPT'.freeze

    # The header key to set the mime type of the response
    #
    # @since 0.1.0
    # @api private
    CONTENT_TYPE         = 'Content-Type'.freeze

    # The default mime type for an incoming HTTP request
    #
    # @since 0.1.0
    # @api private
    DEFAULT_ACCEPT       = '*/*'.freeze

    # The default mime type that is returned in the response
    #
    # @since 0.1.0
    # @api private
    DEFAULT_CONTENT_TYPE = 'application/octet-stream'.freeze

    # @since 0.2.0
    # @api private
    RACK_ERRORS = 'rack.errors'.freeze

    # This isn't part of Rack SPEC
    #
    # Exception notifiers use <tt>rack.exception</tt> instead of
    # <tt>rack.errors</tt>, so we need to support it.
    #
    # @since 0.5.0
    # @api private
    #
    # @see Hanami::Action::Throwable::RACK_ERRORS
    # @see http://www.rubydoc.info/github/rack/rack/file/SPEC#The_Error_Stream
    # @see https://github.com/hanami/controller/issues/133
    RACK_EXCEPTION = 'rack.exception'.freeze

    # The HTTP header for redirects
    #
    # @since 0.2.0
    # @api private
    LOCATION = 'Location'.freeze

    # Override Ruby's hook for modules.
    # It includes basic Hanami::Action modules to the given class.
    #
    # @param base [Class] the target action
    #
    # @since 0.1.0
    # @api private
    def self.inherited(base)
      base.class_eval do
        include Utils::ClassAttribute
        class_attribute :before_callbacks
        self.before_callbacks = Utils::Callbacks::Chain.new

        class_attribute :after_callbacks
        self.after_callbacks = Utils::Callbacks::Chain.new

        prepend InstanceMethods
        include Validatable if defined?(Validatable)
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
    def self.params_class
      @params_class ||= BaseParams
    end

    # FIXME: make this thread-safe
    def self.accepted_formats
      @accepted_formats ||= []
    end

    # FIXME: make this thread-safe
    def self.handled_exceptions
      @handled_exceptions ||= {}
    end

    # Define a callback for an Action.
    # The callback will be executed **before** the action is called, in the
    # order they are added.
    #
    # @param callbacks [Symbol, Array<Symbol>] a single or multiple symbol(s)
    #   each of them is representing a name of a method available in the
    #   context of the Action.
    #
    # @param blk [Proc] an anonymous function to be executed
    #
    # @return [void]
    #
    # @since 0.3.2
    #
    # @see Hanami::Action::Callbacks::ClassMethods#append_after
    #
    # @example Method names (symbols)
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     before :authenticate, :set_article
    #
    #     def call(params)
    #     end
    #
    #     private
    #     def authenticate
    #       # ...
    #     end
    #
    #     # `params` in the method signature is optional
    #     def set_article(params)
    #       @article = Article.find params[:id]
    #     end
    #   end
    #
    #   # The order of execution will be:
    #   #
    #   # 1. #authenticate
    #   # 2. #set_article
    #   # 3. #call
    #
    # @example Anonymous functions (Procs)
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     before { ... } # 1 do some authentication stuff
    #     before {|params| @article = Article.find params[:id] } # 2
    #
    #     def call(params)
    #     end
    #   end
    #
    #   # The order of execution will be:
    #   #
    #   # 1. authentication
    #   # 2. set the article
    #   # 3. #call
    def self.append_before(*callbacks, &blk)
      before_callbacks.append(*callbacks, &blk)
    end

    class << self
      # @since 0.1.0
      alias before append_before
    end

    # Define a callback for an Action.
    # The callback will be executed **after** the action is called, in the
    # order they are added.
    #
    # @param callbacks [Symbol, Array<Symbol>] a single or multiple symbol(s)
    #   each of them is representing a name of a method available in the
    #   context of the Action.
    #
    # @param blk [Proc] an anonymous function to be executed
    #
    # @return [void]
    #
    # @since 0.3.2
    #
    # @see Hanami::Action::Callbacks::ClassMethods#append_before
    def self.append_after(*callbacks, &blk)
      after_callbacks.append(*callbacks, &blk)
    end

    class << self
      # @since 0.1.0
      alias after append_after
    end

    # Define a callback for an Action.
    # The callback will be executed **before** the action is called.
    # It will add the callback at the beginning of the callbacks' chain.
    #
    # @param callbacks [Symbol, Array<Symbol>] a single or multiple symbol(s)
    #   each of them is representing a name of a method available in the
    #   context of the Action.
    #
    # @param blk [Proc] an anonymous function to be executed
    #
    # @return [void]
    #
    # @since 0.3.2
    #
    # @see Hanami::Action::Callbacks::ClassMethods#prepend_after
    def self.prepend_before(*callbacks, &blk)
      before_callbacks.prepend(*callbacks, &blk)
    end

    # Define a callback for an Action.
    # The callback will be executed **after** the action is called.
    # It will add the callback at the beginning of the callbacks' chain.
    #
    # @param callbacks [Symbol, Array<Symbol>] a single or multiple symbol(s)
    #   each of them is representing a name of a method available in the
    #   context of the Action.
    #
    # @param blk [Proc] an anonymous function to be executed
    #
    # @return [void]
    #
    # @since 0.3.2
    #
    # @see Hanami::Action::Callbacks::ClassMethods#prepend_before
    def self.prepend_after(*callbacks, &blk)
      after_callbacks.prepend(*callbacks, &blk)
    end

    # Restrict the access to the specified mime type symbols.
    #
    # @param formats[Array<Symbol>] one or more symbols representing mime type(s)
    #
    # @raise [Hanami::Controller::UnknownFormatError] if the symbol cannot
    #   be converted into a mime type
    #
    # @since 0.1.0
    #
    # @see Hanami::Controller::Configuration#format
    #
    # @example
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #     accept :html, :json
    #
    #     def call(params)
    #       # ...
    #     end
    #   end
    #
    #   # When called with "*/*"              => 200
    #   # When called with "text/html"        => 200
    #   # When called with "application/json" => 200
    #   # When called with "application/xml"  => 406
    def self.accept(*formats)
      @accepted_formats = *formats
      before :enforce_accepted_mime_types
    end

    # Handle the given exception with an HTTP status code.
    #
    # When the exception is raise during #call execution, it will be
    # translated into the associated HTTP status.
    #
    # This is a fine grained control, for a global configuration see
    # Hanami::Action.handled_exceptions
    #
    # @param exception [Hash] the exception class must be the key and the
    #   HTTP status the value of the hash
    #
    # @since 0.1.0
    #
    # @see Hanami::Action.handled_exceptions
    #
    # @example
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #     handle_exception RecordNotFound => 404
    #
    #     def call(params)
    #       # ...
    #       raise RecordNotFound.new
    #     end
    #   end
    #
    #   Show.new.call({id: 1}) # => [404, {}, ['Not Found']]
    def self.handle_exception(exception)
      handled_exceptions.merge!(exception)
    end

    # Callbacks API instance methods
    #
    # @since 0.1.0
    # @api private
    module InstanceMethods
      def initialize(configuration:, **args)
        super(**args)
        @configuration       = configuration
        @accepted_mime_types = Mime.restrict_mime_types(configuration, self.class.accepted_formats)

        # Exceptions
        @handled_exceptions = @configuration.handled_exceptions.merge(self.class.handled_exceptions)
        @handled_exceptions = Hash[
          @handled_exceptions.sort{|(ex1,_),(ex2,_)| ex1.ancestors.include?(ex2) ? -1 : 1 }
        ]
      end

      # Implements the Rack/Hanami::Action protocol
      #
      # @since 0.1.0
      # @api private
      def call(env)
        halted = catch :halt do
          begin
            params    = self.class.params_class.new(env)
            @request  = Hanami::Action::Request.new(env, params)
            @response = Hanami::Action::Response.new(configuration: configuration, content_type: Mime.calculate_content_type_with_charset(configuration, request, accepted_mime_types), header: configuration.default_headers)
            _run_before_callbacks(@request, @response)
            super @request, @response
            _run_after_callbacks(@request, @response)
          rescue => exception
            _reference_in_rack_errors(@request, exception)
            _handle_exception(@request, @response, exception)
          end
        end

        finish(@request, @response, halted)
      end
    end

    def initialize(**)
    end

    protected

    # Calculates an unique ID for the current request
    #
    # @return [String] The unique ID
    #
    # @since 0.3.0

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
    attr_reader :request

    attr_reader :response

    # Halt the action execution with the given HTTP status code and message.
    #
    # When used, the execution of a callback or of an action is interrupted
    # and the control returns to the framework, that decides how to handle
    # the event.
    #
    # If a message is provided, it sets the response body with the message.
    # Otherwise, it sets the response body with the default message associated
    # to the code (eg 404 will set `"Not Found"`).
    #
    # @param code [Fixnum] a valid HTTP status code
    # @param message [String] the response body
    #
    # @since 0.2.0
    #
    # @see Hanami::Controller#handled_exceptions
    # @see Hanami::Action::Throwable#handle_exception
    # @see Hanami::Http::Status:ALL
    #
    # @example Basic usage
    #   require 'hanami/controller'
    #
    #   class Show
    #     def call(params)
    #       halt 404
    #     end
    #   end
    #
    #   # => [404, {}, ["Not Found"]]
    #
    # @example Custom message
    #   require 'hanami/controller'
    #
    #   class Show
    #     def call(params)
    #       halt 404, "This is not the droid you're looking for."
    #     end
    #   end
    #
    #   # => [404, {}, ["This is not the droid you're looking for."]]
    def halt(code, message = nil)
      message ||= Http::Status.message_for(code)
      throw :halt, [code, message]
    end

    # @since 0.3.2
    # @api private
    def _requires_no_body?(req, res)
      HTTP_STATUSES_WITHOUT_BODY.include?(res.status) || req.head?
    end

    private

    attr_reader :configuration

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
        Rack::File.new(path, configuration.public_directory).call(request.env)
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
      directory = configuration.root_directory if Pathname.new(path).relative?

      _send_file(
        Rack::File.new(path, directory).call(request.env)
      )
    end

    # @since 1.0.0
    # @api private
    def _send_file(send_file_response)
      response.headers.merge!(send_file_response[RESPONSE_HEADERS])

      if send_file_response[RESPONSE_CODE] == NOT_FOUND
        response.headers.delete(X_CASCADE)
        response.headers.delete(CONTENT_LENGTH)
        halt NOT_FOUND
      else
        halt send_file_response[RESPONSE_CODE], send_file_response[RESPONSE_BODY]
      end
    end

    def accepted_mime_types
      @accepted_mime_types || configuration.mime_types
    end

    def enforce_accepted_mime_types(req, *)
      Mime.accepted_mime_type?(req, accepted_mime_types) or halt 406
    end

    # Redirect to the given URL and halt the request
    #
    # @param url [String] the destination URL
    # @param status [Fixnum] the http code
    #
    # @since 0.1.0
    #
    # @see Hanami::Action::Throwable#halt
    #
    # @example With default status code (302)
    #   require 'hanami/controller'
    #
    #   class Create
    #     include Hanami::Action
    #
    #     def call(params)
    #       # ...
    #       redirect_to 'http://example.com/articles/23'
    #     end
    #   end
    #
    #   action = Create.new
    #   action.call({}) # => [302, {'Location' => '/articles/23'}, '']
    #
    # @example With custom status code
    #   require 'hanami/controller'
    #
    #   class Create
    #     include Hanami::Action
    #
    #     def call(params)
    #       # ...
    #       redirect_to 'http://example.com/articles/23', status: 301
    #     end
    #   end
    #
    #   action = Create.new
    #   action.call({}) # => [301, {'Location' => '/articles/23'}, '']
    def redirect_to(url, status: 302)
      response.add_header(LOCATION, ::String.new(url))
      halt(status)
    end

    attr_reader :handled_exceptions

    def handled_exception?(exception)
      !exception_handler_for(exception).nil?
    end

    def exception_handler(exception)
      exception_handler_for(exception) || DEFAULT_ERROR_CODE
    end

    def exception_handler_for(exception)
      handled_exceptions.each do |exception_class, handler|
        return handler if exception.kind_of?(exception_class)
      end

      nil
    end

    def handle_exceptions?
      configuration.handle_exceptions
    end

    # @since 0.2.0
    # @api private
    def _reference_in_rack_errors(req, exception)
      return if handled_exception?(exception)

      req.env[RACK_EXCEPTION] = exception

      if errors = req.env[RACK_ERRORS]
        errors.write(_dump_exception(exception))
        errors.flush
      end
    end

    # @since 0.2.0
    # @api private
    def _dump_exception(exception)
      [[exception.class, exception.message].compact.join(": "), *exception.backtrace].join("\n\t")
    end

    # @since 0.1.0
    # @api private
    def _handle_exception(req, res, exception)
      raise unless handle_exceptions?

      instance_exec(
        req,
        res,
        exception,
        &_exception_handler(exception)
      )

      nil
    end

    # @since 0.3.0
    # @api private
    def _exception_handler(exception)
      handler = exception_handler(exception)

      if respond_to?(handler.to_s, true)
        method(handler)
      else
        ->(*) { halt handler }
      end
    end

    # @since 0.1.0
    # @api private
    def _run_before_callbacks(*args)
      self.class.before_callbacks.run(self, *args)
      nil
    end

    # @since 0.1.0
    # @api private
    def _run_after_callbacks(*args)
      self.class.after_callbacks.run(self, *args)
      nil
    end

    # According to RFC 2616, when a response MUST have an empty body, it only
    # allows Entity Headers.
    #
    # For instance, a <tt>204</tt> doesn't allow <tt>Content-Type</tt> or any
    # other custom header.
    #
    # This restriction is enforced by <tt>Hanami::Action::Head#finish</tt>.
    #
    # However, there are cases that demand to bypass this rule to set meta
    # informations via headers.
    #
    # An example is a <tt>DELETE</tt> request for a JSON API application.
    # It returns a <tt>204</tt> but still wants to specify the rate limit
    # quota via <tt>X-Rate-Limit</tt>.
    #
    # @since 0.5.0
    #
    # @see Hanami::Action::HEAD#finish
    #
    # @example
    #   require 'hanami/controller'
    #
    #   module Books
    #     class Destroy
    #       include Hanami::Action
    #
    #       def call(params)
    #         # ...
    #         self.headers.merge!(
    #           'Last-Modified' => 'Fri, 27 Nov 2015 13:32:36 GMT',
    #           'X-Rate-Limit'  => '4000',
    #           'Content-Type'  => 'application/json',
    #           'X-No-Pass'     => 'true'
    #         )
    #
    #         self.status = 204
    #       end
    #
    #       private
    #
    #       def keep_response_header?(header)
    #         super || header == 'X-Rate-Limit'
    #       end
    #     end
    #   end
    #
    #   # Only the following headers will be sent:
    #   #  * Last-Modified - because we used `super' in the method that respects the HTTP RFC
    #   #  * X-Rate-Limit  - because we explicitely allow it
    #
    #   # Both Content-Type and X-No-Pass are removed because they're not allowed
    def keep_response_header?(header)
      ENTITY_HEADERS.include?(header)
    end

    # Finalize the response
    #
    # This method is abstract and COULD be implemented by included modules in
    # order to prepare their data before the response will be returned to the
    # webserver.
    #
    # @since 0.1.0
    # @api private
    # @abstract
    #
    # @see Hanami::Action::Callable#finish
    # @see Hanami::Action::Session#finish
    # @see Hanami::Action::Cookies#finish
    # @see Hanami::Action::Cache#finish
    # @see Hanami::Action::Head#finish
    def finish(req, res, halted)
      res.status, res.body = *halted unless halted.nil?

      if _requires_no_body?(req, res)
        res.body = nil
        res.headers.select! { |header, _| keep_response_header?(header) }
      end

      res[:params] = req.params
      res
    end
  end
end
