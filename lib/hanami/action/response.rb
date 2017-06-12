require 'rack'
require 'rack/response'

module Hanami
  class Action
    class Response < ::Rack::Response
      attr_reader :exposures

      def initialize(body: [], status: 200, header: {})
        super(body, status, header.dup)
        @exposures = {}
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

      def [](key)
        @exposures.fetch(key)
      end

      def []=(key, value)
        @exposures[key] = value
      end
    end
  end
end
