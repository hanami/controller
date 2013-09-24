require 'rack/response'

module Lotus
  module HTTP
    class Response < ::Rack::Response
      attr_reader :action
      attr_writer :header

      def self.fabricate(response)
        new(NullAction.new).tap do |r|
          r.status = response[0] if response[0]
          r.header = response[1] if response[1]
          r.body   = response[2] if response[2]
        end
      end

      def initialize(action)
        super()
        @action = action
      end

      def body=(body)
        if body.respond_to?(:each)
          super body
        else
          super Array(body)
        end
      end

      private
      class NullAction
        def exposures; {}; end
      end
    end
  end
end

