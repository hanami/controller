require 'lotus/http/request'
require 'lotus/http/response'
require 'lotus/action/params'

module Lotus
  module Action
    module Callable
      def call(env)
        _rescue do
          @_env    = env
          @headers = ::Rack::Utils::HeaderHash.new
          @_request  = HTTP::Request.new(env.dup)
          @_response = HTTP::Response.new(self)
          super        Params.new(env)
        end

        finish
      end

      protected

      def finish
        super
        response
      end
    end
  end
end
