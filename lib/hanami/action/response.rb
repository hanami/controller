require 'rack'
require 'rack/response'
require 'hanami/utils/kernel'
require 'hanami/action/flash'
require 'hanami/action/halt'
require 'hanami/action/cookie_jar'

module Hanami
  class Action
    class Response < ::Rack::Response
      SESSION_KEY = "rack.session".freeze
      REQUEST_ID  = "hanami.request_id".freeze
      LOCATION    = "Location".freeze

      X_CASCADE = "X-Cascade".freeze
      CONTENT_LENGTH = "Content-Length".freeze
      NOT_FOUND = 404

      RACK_STATUS  = 0
      RACK_HEADERS = 1
      RACK_BODY    = 2

      attr_reader :exposures, :format, :env
      attr_accessor :charset

      def initialize(configuration:, content_type: nil, env: {}, header: {})
        super([], 200, header.dup)
        set_header("Content-Type", content_type)

        @configuration = configuration
        @charset   = ::Rack::MediaType.params(content_type).fetch('charset', nil)
        @exposures = {}
        @env       = env
      end

      def body=(str)
        @length = 0
        @body   = []

        # FIXME: there could be a bug that prevents Content-Length to be sent for files
        if str.is_a?(::Rack::File::Iterator)
          @body = str
        else
          write(str) unless str.nil?
        end
      end

      def format=(args)
        @format, content_type = *args
        content_type = Action::Mime.content_type_with_charset(content_type, charset)
        set_header("Content-Type", content_type)
      end

      def [](key)
        @exposures.fetch(key)
      end

      def []=(key, value)
        @exposures[key] = value
      end

      def session
        env[SESSION_KEY] ||= {}
      end

      def cookies
        @cookies ||= CookieJar.new(env.dup, headers, @configuration.cookies)
      end

      def flash
        @flash ||= Flash.new(session, request_id)
      end

      def redirect_to(url, status: 302)
        redirect(::String.new(url), status)
        Halt.call(status)
      end

      def send_file(path)
        _send_file(
          Rack::File.new(path, @configuration.public_directory).call(env)
        )
      end

      def unsafe_send_file(path)
        directory = @configuration.root_directory if Pathname.new(path).relative?

        _send_file(
          Rack::File.new(path, directory).call(env)
        )
      end

      # @api private
      def request_id
        env.fetch(REQUEST_ID) do
          # FIXME: raise a meaningful error, by inviting devs to include Hanami::Action::Session
          raise "Can't find request ID"
        end
      end

      def set_format(value)
        @format = value
      end

      # @api private
      def _send_file(send_file_response)
        headers.merge!(send_file_response[RACK_HEADERS])

        if send_file_response[RACK_STATUS] == NOT_FOUND
          headers.delete(X_CASCADE)
          headers.delete(CONTENT_LENGTH)
          Halt.call(NOT_FOUND)
        else
          Halt.call(send_file_response[RACK_STATUS], send_file_response[RACK_BODY])
        end
      end
    end
  end
end
