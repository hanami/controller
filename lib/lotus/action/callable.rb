require 'rack/request'
require 'rack/response'
require 'lotus/action/params'

module Lotus
  module Action
    module Callable
      def call(env)
        _rescue do
          @_request  = ::Rack::Request.new(env.dup)
          @_response = ::Rack::Response.new
          super        Params.new(env)
        end

        finish
      end

      protected

      def finish
        super
        @_response
      end
    end
  end
end
