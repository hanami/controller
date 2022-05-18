# frozen_string_literal: true

require "rack"
require "rack/response"
require "hanami/utils/kernel"
require "hanami/action/flash"
require "hanami/action/halt"
require "hanami/action/cookie_jar"
require "hanami/action/cache/cache_control"
require "hanami/action/cache/expires"
require "hanami/action/cache/conditional_get"

module Hanami
  class Action
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
      attr_reader :request, :action, :exposures, :format, :env, :view_options, :sessions_enabled

      # @since 2.0.0
      # @api private
      attr_accessor :charset

      # @since 2.0.0
      # @api private
      def self.build(status, env)
        new(action: "", configuration: nil, content_type: Mime.best_q_match(env[Action::HTTP_ACCEPT]), env: env).tap do |r| # rubocop:disable Layout/LineLength
          r.status = status
          r.body   = Http::Status.message_for(status)
          r.set_format(Mime.format_for(r.content_type))
        end
      end

      # @since 2.0.0
      # @api private
      def initialize(request:, action:, configuration:, content_type: nil, env: {}, headers: {}, view_options: nil, sessions_enabled: false) # rubocop:disable Metrics/ParameterLists
        super([], 200, headers.dup)
        set_header(Action::CONTENT_TYPE, content_type)

        @request = request
        @action = action
        @configuration = configuration
        @charset = ::Rack::MediaType.params(content_type).fetch("charset", nil)
        @exposures = {}
        @env = env
        @view_options = view_options || DEFAULT_VIEW_OPTIONS

        @sessions_enabled = sessions_enabled
        @sending_file = false
      end

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

      # @since 2.0.0
      # @api public
      def render(view, **options)
        self.body = view.(**view_options.(request, self), **exposures.merge(options)).to_str
      end

      # @since 2.0.0
      # @api public
      def format=(args)
        @format, content_type = *args
        content_type = Action::Mime.content_type_with_charset(content_type, charset)
        set_header("Content-Type", content_type)
      end

      # @since 2.0.0
      # @api public
      def [](key)
        @exposures.fetch(key)
      end

      # @since 2.0.0
      # @api public
      def []=(key, value)
        @exposures[key] = value
      end

      # @since 2.0.0
      # @api public
      def session
        unless sessions_enabled
          raise Hanami::Action::MissingSessionError.new("Hanami::Action::Response#session")
        end

        env[Action::RACK_SESSION] ||= {}
      end

      # @since 2.0.0
      # @api public
      def cookies
        @cookies ||= CookieJar.new(env.dup, headers, @configuration.cookies)
      end

      # @since 2.0.0
      # @api public
      def flash
        unless sessions_enabled
          raise Hanami::Action::MissingSessionError.new("Hanami::Action::Response#flash")
        end

        @flash ||= Flash.new(session[Flash::KEY])
      end

      # @since 2.0.0
      # @api public
      def redirect_to(url, status: 302)
        return unless allow_redirect?

        redirect(::String.new(url), status)
        Halt.call(status)
      end

      # @since 2.0.0
      # @api public
      def send_file(path)
        _send_file(
          Rack::File.new(path, @configuration.public_directory).call(env)
        )
      end

      # @since 2.0.0
      # @api public
      def unsafe_send_file(path)
        directory = if Pathname.new(path).relative?
                      @configuration.root_directory
                    else
                      FILE_SYSTEM_ROOT
                    end

        _send_file(
          Rack::File.new(path, directory).call(env)
        )
      end

      # @since 2.0.0
      # @api public
      def cache_control(*values)
        directives = Cache::CacheControl::Directives.new(*values)
        headers.merge!(directives.headers)
      end

      # @since 2.0.0
      # @api public
      def expires(amount, *values)
        directives = Cache::Expires::Directives.new(amount, *values)
        headers.merge!(directives.headers)
      end

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
      def request_id
        env.fetch(Action::REQUEST_ID) do
          # FIXME: raise a meaningful error, by inviting devs to include Hanami::Action::Session
          # raise "Can't find request ID"
          raise Hanami::Action::MissingSessionError.new('request_id')
        end
      end

      # @since 2.0.0
      # @api public
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
      # @api public
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
