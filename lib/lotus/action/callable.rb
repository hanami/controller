require 'rack/request'
require 'rack/response'
require 'lotus/action/params'

module Lotus
  module Action
    module Callable
      def call(env)
        _rescue do
          @_request  = Rack::Request.new(env)
          @_response = Rack::Response.new
          super        Params.new(env, @_request)
        end

        @_response
      end

      protected
      def status=(status)
        @_response.status = status
      end

      def body=(body)
        @_response.body = [ body ]
      end

      def headers
        @_response.headers
      end

      def session
        @_request.session
      end

      def redirect_to(url, status: 302)
        @_response.redirect(url, status)
      end

      private
      def _rescue
        begin
          yield
        rescue
          self.status = 500
          self.body   = 'Internal Server Error'
        end
      end
    end
  end
end
