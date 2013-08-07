require 'rack/response'

module Lotus
  module HTTP
    class Response < ::Rack::Response
      attr_reader :action

      def initialize(action)
        super()
        @action = action
      end
    end
  end
end

