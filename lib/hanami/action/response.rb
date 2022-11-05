# frozen_string_literal: true

require "rack"
require "rack/response"
require "hanami/utils/kernel"
require "hanami/action/halt"
require "hanami/action/cookie_jar"
require "hanami/action/cache/cache_control"
require "hanami/action/cache/expires"
require "hanami/action/cache/conditional_get"
require_relative "errors"

module Hanami
  class Action
    # The HTTP response for an action, given to {Action#handle}.
    #
    # Inherits from `Rack::Response`, providing compatibility with Rack functionality.
    #
    # @see http://www.rubydoc.info/gems/rack/Rack/Response
    #
    # @since 2.0.0
    # @api private
    class Response < ::Rack::Response
      # @since 2.0.0
      # @api private
      DEFAULT_VIEW_OPTIONS = -> (*) { {} }.freeze

      # @since 2.0.0
      # @api private
      EMPTY_BODY = [].freeze

      # @since 2.0.0
      # @api private
      FILE_SYSTEM_ROOT = Pathname.new("/").freeze

      # @since 2.0.0
      # @api private
      attr_reader :request, :exposures, :env, :view_options

      # @since 2.0.0
      # @api private
      attr_accessor :charset

      # @since 2.0.0
      # @api private
      def self.build(status, env)
        new(config: nil, content_type: Mime.best_q_match(env[Action::HTTP_ACCEPT]), env: env).tap do |r|
          r.status = status
          r.body   = Http::Status.message_for(status)
          r.set_format(Mime.format_for(r.content_type))
        end
      end

      # @since 2.0.0
      # @api private
      def initialize(request:, config:, content_type: nil, env: {}, headers: {}, view_options: nil, sessions_enabled: false) # rubocop:disable Layout/LineLength, Metrics/ParameterLists
        super([], 200, headers.dup)
        self.content_type = content_type if content_type

        @request = request
        @config = config
        @charset = ::Rack::MediaType.params(content_type).fetch("charset", nil)
        @exposures = {}
        @env = env
        @view_options = view_options || DEFAULT_VIEW_OPTIONS

        @sessions_enabled = sessions_enabled
        @sending_file = false
      end

      # Sets the response body.
      #
      # @param str [String] the body string
      #
      # @since 2.0.0
      # @api public
      def body=(str)
        @length = 0
        @body   = EMPTY_BODY.dup

        # FIXME: there could be a bug that prevents Content-Length to be sent for files
        if str.is_a?(::Rack::File::Iterator)
          @body = str
        else
          write(str) unless str.nil? || str == EMPTY_BODY
        end
      end

      # This is NOT RELEASED with 2.0.0
      #
      # @api private
      def render(view, **options)
        self.body = view.(**view_options.(request, self), **exposures.merge(options)).to_str
      end

      # Returns the format for the response.
      #
      # Returns nil if a format has not been assigned and also cannot be determined from the
      # response's {#content_type}.
      #
      # @example
      #   response.format # => :json
      #
      # @return [Symbol, nil]
      #
      # @since 2.0.0
      # @api public
      def format
        @format ||= Mime.detect_format(content_type, @config)
      end

      # Sets the format and associated content type for the response.
      #
      # Either a format name (`:json`) or a content type string (`"application/json"`) may be given.
      # In either case, the format or content type will be derived from the given value, and both
      # will be set.
      #
      # @example Assigning via a format name symbol
      #   response.format = :json
      #   response.content_type # => "application/json"
      #   response.headers["Content-Type"] # => "application/json"
      #
      # @example Assigning via a content type string
      #   response.format = "application/json"
      #   response.format # => :json
      #   response.content_type # => "application/json"
      #
      # @param value [Symbol, String] the format name or content type
      #
      # @see Config#formats
      #
      # @since 2.0.0
      # @api public
      def format=(value)
        format, content_type = Mime.detect_format_and_content_type(value, @config)

        self.content_type = Mime.content_type_with_charset(content_type, charset)

        @format = format
      end

      # Returns the exposure value for the given key.
      #
      # @param key [Object]
      #
      # @return [Object] the exposure value, if found
      #
      # @raise [KeyError] if the exposure was not found
      #
      # @since 2.0.0
      # @api public
      def [](key)
        @exposures.fetch(key)
      end

      # Sets an exposure value for the given key.
      #
      # @param key [Object]
      # @param value [Object]
      #
      # @return [Object] the value
      #
      # @since 2.0.0
      # @api public
      def []=(key, value)
        @exposures[key] = value
      end

      # Returns the session for the response.
      #
      # This is the same session object as the {Request}.
      #
      # @return [Hash] the session object
      #
      # @raise [MissingSessionError] if sessions are not enabled
      #
      # @see Request#session
      #
      # @since 2.0.0
      # @api public
      def session
        unless @sessions_enabled
          raise Hanami::Action::MissingSessionError.new("Hanami::Action::Response#session")
        end

        request.session
      end

      # Returns the flash for the request.
      #
      # This is the same flash object as the {Request}.
      #
      # @return [Flash]
      #
      # @raise [MissingSessionError] if sessions are not enabled
      #
      # @see Request#flash
      #
      # @since 2.0.0
      # @api public
      def flash
        unless @sessions_enabled
          raise Hanami::Action::MissingSessionError.new("Hanami::Action::Response#flash")
        end

        request.flash
      end

      # Returns the set of cookies to be included in the response.
      #
      # @return [CookieJar]
      #
      # @since 2.0.0
      # @api public
      def cookies
        @cookies ||= CookieJar.new(env.dup, headers, @config.cookies)
      end

      # Sets the response to redirect to the given URL and halts further handling.
      #
      # @param url [String]
      # @param status [Integer] the HTTP status to use for the redirect
      #
      # @since 2.0.0
      # @api public
      def redirect_to(url, status: 302)
        return unless allow_redirect?

        redirect(::String.new(url), status)
        Halt.call(status)
      end

      # Sends the file at the given path as the response, for any file within the configured
      # `public_directory`.
      #
      # Handles the following aspects for file responses:
      #
      # - Setting `Content-Type` and `Content-Length` headers
      # - File Not Found responses (returns a 404)
      # - Conditional GET (via `If-Modified-Since` header)
      # - Range requests (via `Range` header)
      #
      # @param path [String] the file path
      #
      # @return [void]
      #
      # @see Config#public_directory
      #
      # @since 2.0.0
      # @api public
      def send_file(path)
        _send_file(
          Rack::File.new(path, @config.public_directory).call(env)
        )
      end

      # Send the file at the given path as the response, for a file anywhere in the file system.
      #
      # @see #send_file
      #
      # @param path [String, Pathname] path to the file to be sent
      #
      # @return [void]
      #
      # @since 2.0.0
      # @api public
      def unsafe_send_file(path)
        directory = if Pathname.new(path).relative?
                      @config.root_directory
                    else
                      FILE_SYSTEM_ROOT
                    end

        _send_file(
          Rack::File.new(path, directory).call(env)
        )
      end

      # Specifies the response freshness policy for HTTP caches using the `Cache-Control` header.
      #
      # Any number of non-value directives (`:public`, `:private`, `:no_cache`, `:no_store`,
      # `:must_revalidate`, `:proxy_revalidate`) may be passed along with a Hash of value directives
      # (`:max_age`, `:min_stale`, `:s_max_age`).
      #
      # See [RFC 2616 / 14.9](http://tools.ietf.org/html/rfc2616#section-14.9.1) for more on
      # standard cache control directives.
      #
      # @example
      #   # Set Cache-Control directives
      #   response.cache_control :public, max_age: 900, s_maxage: 86400
      #
      #   # Overwrite previous Cache-Control directives
      #   response.cache_control :private, :no_cache, :no_store
      #
      #   response.get_header("Cache-Control") # => "private, no-store, max-age=900"
      #
      # @param values [Array<Symbol, Hash>] values to map to `Cache-Control` directives
      # @option values [Symbol] :public
      # @option values [Symbol] :private
      # @option values [Symbol] :no_cache
      # @option values [Symbol] :no_store
      # @option values [Symbol] :must_validate
      # @option values [Symbol] :proxy_revalidate
      # @option values [Hash] :max_age
      # @option values [Hash] :min_stale
      # @option values [Hash] :s_max_age
      #
      # @return void
      #
      # @since 2.0.0
      # @api public
      def cache_control(*values)
        directives = Cache::CacheControl::Directives.new(*values)
        headers.merge!(directives.headers)
      end

      # Sets the `Expires` header and `Cache-Control`/`max-age` directive for the response.
      #
      # You can provide an integer number of seconds in the future, or a Time object indicating when
      # the response should be considered "stale". The remaining arguments are passed to
      # {#cache_control}.
      #
      # @example
      #   # Set Cache-Control directives and Expires
      #   response.expires 900, :public
      #
      #   # Overwrite Cache-Control directives and Expires
      #   response.expires 300, :private, :no_cache, :no_store
      #
      #   response.get_header("Expires") # => "Thu, 26 Jun 2014 12:00:00 GMT"
      #   response.get_header("Cache-Control") # => "private, no-cache, no-store max-age=300"
      #
      # @param amount [Integer, Time] number of seconds or point in time
      # @param values [Array<Symbols>] values to map to `Cache-Control` directives via
      #   {#cache_control}
      #
      # @return void
      #
      # @since 2.0.0
      # @api public
      def expires(amount, *values)
        directives = Cache::Expires::Directives.new(amount, *values)
        headers.merge!(directives.headers)
      end

      # Sets the `etag` and/or `last_modified` headers on the response and halts with a `304 Not
      # Modified` response if the request is still fresh according to the `IfNoneMatch` and
      # `IfModifiedSince` request headers.
      #
      # @example
      #   # Set etag header and halt 304 if request matches IF_NONE_MATCH header
      #   response.fresh etag: some_resource.updated_at.to_i
      #
      #   # Set last_modified header and halt 304 if request matches IF_MODIFIED_SINCE
      #   response.fresh last_modified: some_resource.updated_at
      #
      #   # Set etag and last_modified header and halt 304 if request matches IF_MODIFIED_SINCE and IF_NONE_MATCH
      #   response.fresh last_modified: some_resource.updated_at
      #
      # @param options [Hash]
      # @option options [Integer] :etag for testing IfNoneMatch conditions
      # @option options [Date] :last_modified for testing IfModifiedSince conditions
      #
      # @return void
      #
      # @since 2.0.0
      # @api public
      def fresh(options)
        conditional_get = Cache::ConditionalGet.new(env, options)

        headers.merge!(conditional_get.headers)

        conditional_get.fresh? do
          Halt.call(304)
        end
      end

      # @since 2.0.0
      # @api private
      def set_format(value) # rubocop:disable Naming/AccessorMethodName
        @format = value
      end

      # @since 2.0.0
      # @api private
      def renderable?
        return !head? && body.empty? if body.respond_to?(:empty?)

        !@sending_file && !head?
      end

      # @since 2.0.0
      # @api private
      def allow_redirect?
        return body.empty? if body.respond_to?(:empty?)

        !@sending_file
      end

      # @since 2.0.0
      # @api private
      alias_method :to_ary, :to_a

      # @since 2.0.0
      # @api private
      def head?
        env[Action::REQUEST_METHOD] == Action::HEAD
      end

      # @since 2.0.0
      # @api private
      def _send_file(send_file_response)
        headers.merge!(send_file_response[Action::RESPONSE_HEADERS])

        if send_file_response[Action::RESPONSE_CODE] == Action::NOT_FOUND
          headers.delete(Action::X_CASCADE)
          headers.delete(Action::CONTENT_LENGTH)
          Halt.call(Action::NOT_FOUND)
        else
          self.status = send_file_response[Action::RESPONSE_CODE]
          self.body = send_file_response[Action::RESPONSE_BODY]
          @sending_file = true
        end
      end
    end
  end
end
