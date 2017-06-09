begin
  require 'hanami/validations'
  require 'hanami/action/validatable'
rescue LoadError
end

require 'securerandom'
require 'hanami/action/request'
require 'hanami/action/response'
require 'hanami/action/base_params'
require 'hanami/action/rack/file'

require 'rack/utils'
require 'hanami/utils'
require 'hanami/utils/kernel'

require 'hanami/action/exposable/guard'

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

    # The default charset that is returned in the response
    #
    # @since 0.3.0
    # @api private
    DEFAULT_CHARSET = 'utf-8'.freeze

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

    # Most commom MIME Types used for responses
    #
    # @since 1.0.0
    # @api private
    MIME_TYPES = {
      txt: 'text/plain',
      html: 'text/html',
      json: 'application/json',
      manifest: 'text/cache-manifest',
      atom: 'application/atom+xml',
      avi: 'video/x-msvideo',
      bmp: 'image/bmp',
      bz: 'application/x-bzip',
      bz2: 'application/x-bzip2',
      chm: 'application/vnd.ms-htmlhelp',
      css: 'text/css',
      csv: 'text/csv',
      flv: 'video/x-flv',
      gif: 'image/gif',
      gz: 'application/x-gzip',
      h264: 'video/h264',
      ico: 'image/vnd.microsoft.icon',
      ics: 'text/calendar',
      jpg: 'image/jpeg',
      js: 'application/javascript',
      mp4: 'video/mp4',
      mov: 'video/quicktime',
      mp3: 'audio/mpeg',
      mp4a: 'audio/mp4',
      mpg: 'video/mpeg',
      oga: 'audio/ogg',
      ogg: 'application/ogg',
      ogv: 'video/ogg',
      pdf: 'application/pdf',
      pgp: 'application/pgp-encrypted',
      png: 'image/png',
      psd: 'image/vnd.adobe.photoshop',
      rtf: 'application/rtf',
      sh: 'application/x-sh',
      svg: 'image/svg+xml',
      swf: 'application/x-shockwave-flash',
      tar: 'application/x-tar',
      torrent: 'application/x-bittorrent',
      tsv: 'text/tab-separated-values',
      uri: 'text/uri-list',
      vcs: 'text/x-vcalendar',
      wav: 'audio/x-wav',
      webm: 'video/webm',
      wmv: 'video/x-ms-wmv',
      woff: 'application/font-woff',
      woff2: 'application/font-woff2',
      wsdl: 'application/wsdl+xml',
      xhtml: 'application/xhtml+xml',
      xml: 'application/xml',
      xslt: 'application/xslt+xml',
      yml: 'text/yaml',
      zip: 'application/zip'
    }.freeze

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

        include Exposable::Guard

        prepend InstanceMethods
        _expose :params

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

    # Expose the given attributes on the outside of the object with
    # a getter and a special method called #exposures.
    #
    # @param names [Array<Symbol>] the name(s) of the attribute(s) to be
    #   exposed
    #
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
    #     expose :article, :tags
    #
    #     def call(params)
    #       @article = Article.find params[:id]
    #       @tags    = Tag.for(article)
    #     end
    #   end
    #
    #   action = Show.new
    #   action.call({id: 23})
    #
    #   action.article # => #<Article ...>
    #   action.tags    # => [#<Tag ...>, #<Tag ...>]
    #
    #   action.exposures # => { :article => #<Article ...>, :tags => [ ... ] }
    def self.expose(*names)
      class_eval do
        names.each do |name|
          attr_reader(name) unless attr_reader?(name)
        end

        exposures.push(*names)
      end
    end

    class << self
      # Alias of #expose to be used in internal modules.
      # #_expose is not watched by the Guard
      alias _expose expose
    end

    # Set of exposures attribute names
    #
    # @return [Array] the exposures attribute names
    #
    # @since 0.1.0
    # @api private
    def self.exposures
      @exposures ||= []
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

    # Check if the attr_reader is already defined
    #
    # @since 0.3.0
    # @api private
    def self.attr_reader?(name)
      (instance_methods | private_instance_methods).include?(name)
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
        @configuration = configuration

        # MIME Types
        @accepted_mime_types = @configuration.restrict_mime_types(
          self.class.accepted_formats.map do |format|
            format_to_mime_type(format)
          end
        )

        @accepted_mime_types = nil if @accepted_mime_types.empty?

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
        _rescue do
          @_env     = env
          @headers  = ::Rack::Utils::HeaderHash.new(configuration.default_headers)
          @params   = self.class.params_class.new(@_env)
          @request  = Hanami::Action::Request.new(@_env, @params)
          @response = Hanami::Action::Response.new
          _run_before_callbacks(@params)
          super @request, @response
          _run_after_callbacks(@params)
        end

        finish
      end
    end

    def initialize(**)
      @_status = nil
      @_body   = nil
      @content_type = nil
      @charset      = nil
    end

    # Returns a symbol representation of the content type.
    #
    # The framework automatically detects the request mime type, and returns
    # the corresponding format.
    #
    # However, if this value was explicitly set by `#format=`, it will return
    # that value
    #
    # @return [Symbol] a symbol that corresponds to the content type
    #
    # @since 0.2.0
    #
    # @see Hanami::Action::Mime#format=
    # @see Hanami::Action::Mime#content_type
    #
    # @example Default scenario
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     def call(params)
    #     end
    #   end
    #
    #   action = Show.new
    #
    #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => 'text/html' })
    #   headers['Content-Type'] # => 'text/html'
    #   action.format           # => :html
    #
    # @example Set value
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     def call(params)
    #       self.format = :xml
    #     end
    #   end
    #
    #   action = Show.new
    #
    #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => 'text/html' })
    #   headers['Content-Type'] # => 'application/xml'
    #   action.format           # => :xml
    def format
      @format ||= detect_format
    end

    # The content type that will be automatically set in the response.
    #
    # It prefers, in order:
    #   * Explicit set value (see Hanami::Action::Mime#format=)
    #   * Weighted value from Accept header based on all known MIME Types:
    #     - Custom registered MIME Types (see Hanami::Controller::Configuration#format)
    #   * Configured default content type (see Hanami::Controller::Configuration#default_response_format)
    #   * Hard-coded default content type (see Hanami::Action::Mime::DEFAULT_CONTENT_TYPE)
    #
    # To override the value, use <tt>#format=</tt>
    #
    # @return [String] the content type from the request.
    #
    # @since 0.1.0
    #
    # @see Hanami::Action::Mime#format=
    # @see Hanami::Configuration#default_request_format
    # @see Hanami::Action::Mime#default_content_type
    # @see Hanami::Action::Mime#DEFAULT_CONTENT_TYPE
    # @see Hanami::Controller::Configuration#format
    # @see Hanami::Controller::Configuration#default_response_format
    #
    # @example
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     def call(params)
    #       # ...
    #       content_type # => 'text/html'
    #     end
    #   end
    def content_type
      return @content_type unless @content_type.nil?

      if accept_header?
        type = content_type_from_accept_header
        return type if type
      end

      default_response_type || default_content_type || DEFAULT_CONTENT_TYPE
    end

    # Action charset setter, receives new charset value
    #
    # @return [String] the charset of the request.
    #
    # @since 0.3.0
    #
    # @example
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     def call(params)
    #       # ...
    #       self.charset = 'koi8-r'
    #     end
    #   end
    def charset=(value)
      @charset = value
    end

    # The charset that will be automatically set in the response.
    #
    # It prefers, in order:
    #   * Explicit set value (see #charset=)
    #   * Default configuration charset
    #   * Default content type
    #
    # To override the value, use <tt>#charset=</tt>
    #
    # @return [String] the charset of the request.
    #
    # @since 0.3.0
    #
    # @see Hanami::Action::Mime#charset=
    # @see Hanami::Configuration#default_charset
    # @see Hanami::Action::Mime#default_charset
    # @see Hanami::Action::Mime#DEFAULT_CHARSET
    #
    # @example
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     def call(params)
    #       # ...
    #       charset # => 'text/html'
    #     end
    #   end
    def charset
      @charset || default_charset || DEFAULT_CHARSET
    end

    # Set of exposures
    #
    # @return [Hash] the exposures
    #
    # @since 0.1.0
    #
    # @see Hanami::Action::Exposable::ClassMethods.expose
    def exposures
      @exposures ||= {}.tap do |result|
        self.class.exposures.each do |name|
          result[name] = send(name)
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
    attr_reader :request

    # Return parsed request body
    def parsed_request_body
      @_env.fetch(ROUTER_PARSED_BODY, nil)
    end

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
      status(code, message)

      throw :halt
    end

    # Sets the given code and message for the response
    #
    # @param code [Fixnum] a valid HTTP status code
    # @param message [String] the response body
    #
    # @since 0.1.0
    # @see Hanami::Http::Status:ALL
    def status(code, message)
      self.status = code
      self.body   = message
    end

    # @since 0.3.2
    # @api private
    def _requires_no_body?
      HTTP_STATUSES_WITHOUT_BODY.include?(@_status) || head?
    end

    private

    attr_reader :configuration

    # Sets the HTTP status code for the response
    #
    # @param status [Fixnum] an HTTP status code
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
        Rack::File.new(path, configuration.public_directory).call(@_env)
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
        Rack::File.new(path, directory).call(@_env)
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
        halt response[RESPONSE_CODE], response[RESPONSE_BODY]
      end
    end

    # Sets the given format and corresponding content type.
    #
    # The framework detects the `HTTP_ACCEPT` header of the request and sets
    # the proper `Content-Type` header in the response.
    # Within this default scenario, `#format` returns a symbol that
    # corresponds to `#content_type`.
    # For instance, if a client sends an `HTTP_ACCEPT` with `text/html`,
    # `#content_type` will return `text/html` and `#format` `:html`.
    #
    # However, it's possible to override what the framework have detected.
    # If a client asks for an `HTTP_ACCEPT` `*/*`, but we want to force the
    # response to be a `text/html` we can use this method.
    #
    # When the format is set, the framework searches for a corresponding mime
    # type to be set as the `Content-Type` header of the response.
    # This lookup is performed first in the configuration, and then in
    # `Hanami::Action::Mime::MIME_TYPES`. If the lookup fails, it raises an error.
    #
    # PERFORMANCE: Because `Hanami::Controller::Configuration#formats` is
    # smaller and looked up first than `Hanami::Action::Mime::MIME_TYPES`,
    # we suggest to configure the most common mime types used by your
    # application, **even if they are already present in that Rack constant**.
    #
    # @param format [#to_sym] the format
    #
    # @return [void]
    #
    # @raise [TypeError] if the format cannot be coerced into a Symbol
    # @raise [Hanami::Controller::UnknownFormatError] if the format doesn't
    #   have a corresponding mime type
    #
    # @since 0.2.0
    #
    # @see Hanami::Action::Mime#format
    # @see Hanami::Action::Mime#content_type
    # @see Hanami::Controller::Configuration#format
    #
    # @example Default scenario
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     def call(params)
    #     end
    #   end
    #
    #   action = Show.new
    #
    #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => '*/*' })
    #   headers['Content-Type'] # => 'application/octet-stream'
    #   action.format           # => :all
    #
    #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => 'text/html' })
    #   headers['Content-Type'] # => 'text/html'
    #   action.format           # => :html
    #
    # @example Simple usage
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     def call(params)
    #       # ...
    #       self.format = :json
    #     end
    #   end
    #
    #   action = Show.new
    #
    #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => '*/*' })
    #   headers['Content-Type'] # => 'application/json'
    #   action.format           # => :json
    #
    # @example Unknown format
    #   require 'hanami/controller'
    #
    #   class Show
    #     include Hanami::Action
    #
    #     def call(params)
    #       # ...
    #       self.format = :unknown
    #     end
    #   end
    #
    #   action = Show.new
    #   action.call({ 'HTTP_ACCEPT' => '*/*' })
    #     # => raise Hanami::Controller::UnknownFormatError
    #
    # @example Custom mime type/format
    #   require 'hanami/controller'
    #
    #   Hanami::Controller.configure do
    #     format :custom, 'application/custom'
    #   end
    #
    #   class Show
    #     include Hanami::Action
    #
    #     def call(params)
    #       # ...
    #       self.format = :custom
    #     end
    #   end
    #
    #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => '*/*' })
    #   headers['Content-Type'] # => 'application/custom'
    #   action.format           # => :custom
    def format=(format)
      @format       = Utils::Kernel.Symbol(format)
      @content_type = format_to_mime_type(@format)
    end

    # Match the given mime type with the Accept header
    #
    # @return [Boolean] true if the given mime type matches Accept
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
    #       # @_env['HTTP_ACCEPT'] # => 'text/html,application/xhtml+xml,application/xml;q=0.9'
    #
    #       accept?('text/html')        # => true
    #       accept?('application/xml')  # => true
    #       accept?('application/json') # => false
    #
    #
    #
    #       # @_env['HTTP_ACCEPT'] # => '*/*'
    #
    #       accept?('text/html')        # => true
    #       accept?('application/xml')  # => true
    #       accept?('application/json') # => true
    #     end
    #   end
    def accept?(mime_type)
      !!::Rack::Utils.q_values(accept).find do |mime, _|
        ::Rack::Mime.match?(mime_type, mime)
      end
    end

    # @since 0.1.0
    # @api private
    def accept
      @accept ||= @_env[HTTP_ACCEPT] || DEFAULT_ACCEPT
    end

    # Checks if there is an Accept header for the current request.
    #
    # @return [TrueClass,FalseClass] the result of the check
    #
    # @since 0.8.0
    # @api private
    def accept_header?
      accept != DEFAULT_ACCEPT
    end

    def accepted_mime_types
      @accepted_mime_types || configuration.mime_types
    end

    def enforce_accepted_mime_types
      return unless accepted_mime_types.find { |mt| accept?(mt) }.nil?

      halt 406
    end

    # Look at the Accept header for the current request and see if it
    # matches any of the common MIME types (see Hanami::Action::Mime#MIME_TYPES)
    # or the custom registered ones (see Hanami::Controller::Configuration#format).
    #
    # @return [String,Nil] The matched MIME type for the given Accept header.
    #
    # @since 0.8.0
    # @api private
    #
    # @see Hanami::Action::Mime#MIME_TYPES
    # @see Hanami::Controller::Configuration#format
    #
    # @api private
    def content_type_from_accept_header
      best_q_match(accept, accepted_mime_types)
    end

    # @since 0.5.0
    # @api private
    def default_response_type
      format_to_mime_type(default_response_format) if default_response_format
    end

    # @since 0.2.0
    # @api private
    def default_content_type
      format_to_mime_type(
        default_request_format
      ) if default_request_format
    end

    def default_request_format
      configuration.default_request_format
    end

    def default_response_format
      configuration.default_response_format
    end

    def format_to_mime_type(format)
      configuration.mime_type_for(format) ||
        MIME_TYPES[format] or
        raise Hanami::Controller::UnknownFormatError.new(format)
    end

    # @since 0.2.0
    # @api private
    def detect_format
      configuration.format_for(content_type) || MIME_TYPES.key(content_type)
    end

    # @since 0.3.0
    # @api private
    def default_charset
      configuration.default_charset
    end

    # @since 0.3.0
    # @api private
    def content_type_with_charset
      "#{content_type}; charset=#{charset}"
    end

    # Patched version of <tt>Rack::Utils.best_q_match</tt>.
    #
    # @since 0.4.1
    # @api private
    #
    # @see http://www.rubydoc.info/gems/rack/Rack/Utils#best_q_match-class_method
    # @see https://github.com/rack/rack/pull/659
    # @see https://github.com/hanami/controller/issues/59
    # @see https://github.com/hanami/controller/issues/104
    def best_q_match(q_value_header, available_mimes)
      values = ::Rack::Utils.q_values(q_value_header)
      values = values.map do |req_mime, quality|
        if req_mime == DEFAULT_ACCEPT
          # See https://github.com/hanami/controller/issues/167
          match = default_content_type
        else
          match = available_mimes.find { |am| ::Rack::Mime.match?(am, req_mime) }
        end
        next unless match
        [match, quality]
      end.compact

      if Hanami::Utils.jruby?
        # See https://github.com/hanami/controller/issues/59
        # See https://github.com/hanami/controller/issues/104
        values.reverse!
      else
        # See https://github.com/jruby/jruby/issues/3004
        values.sort!
      end

      value = values.sort_by do |match, quality|
        (match.split('/'.freeze, 2).count('*'.freeze) * -10) + quality
      end.last

      value.first if value
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
      headers[LOCATION] = ::String.new(url)
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

    # @since 0.1.0
    # @api private
    def _rescue
      catch :halt do
        begin
          yield
        rescue => exception
          _reference_in_rack_errors(exception)
          _handle_exception(exception)
        end
      end
    end

    # @since 0.2.0
    # @api private
    def _reference_in_rack_errors(exception)
      return if handled_exception?(exception)

      @_env[RACK_EXCEPTION] = exception

      if errors = @_env[RACK_ERRORS]
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
    def _handle_exception(exception)
      raise unless handle_exceptions?

      instance_exec(
        exception,
        &_exception_handler(exception)
      )
    end

    # @since 0.3.0
    # @api private
    def _exception_handler(exception)
      handler = exception_handler(exception)

      if respond_to?(handler.to_s, true)
        method(handler)
      else
        ->(ex) { halt handler }
      end
    end

    # @since 0.1.0
    # @api private
    def _run_before_callbacks(params)
      self.class.before_callbacks.run(self, params)
    end

    # @since 0.1.0
    # @api private
    def _run_after_callbacks(params)
      self.class.after_callbacks.run(self, params)
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
    # @see Hanami::Action::Exposable#finish
    # @see Hanami::Action::Callable#finish
    # @see Hanami::Action::Session#finish
    # @see Hanami::Action::Cookies#finish
    # @see Hanami::Action::Cache#finish
    # @see Hanami::Action::Head#finish
    def finish
      headers[CONTENT_TYPE] ||= content_type_with_charset

      if _requires_no_body?
        @_body = nil
        @headers.reject! {|header,_| !keep_response_header?(header) }
      end

      exposures
      response
    end
  end
end
