require 'rack'
require 'rack/response'
require 'hanami/utils/kernel'
require 'hanami/action/flash'

module Hanami
  class Action
    class Response < ::Rack::Response
      SESSION_KEY = "rack.session".freeze
      REQUEST_ID  = "hanami.request_id".freeze

      attr_reader :exposures, :format, :env
      attr_accessor :charset

      def initialize(content_type: nil, env: {}, header: {})
        super([], 200, header.dup)
        set_header("Content-Type", content_type)

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

      def flash
        @flash ||= Flash.new(session, request_id)
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
    end
  end
end
