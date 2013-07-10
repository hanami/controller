require 'rack/request'
require 'rack/response'
require 'lotus/http/status'
require 'lotus/action/params'
require 'lotus/action/cookie_jar'

module Lotus
  module Action
    module Callable
      def call(env)
        _rescue do
          @_request  = Rack::Request.new(env.dup)
          @_response = Rack::Response.new
          super        Params.new(env)
        end

        cookies.finish
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

      def cookies
        @cookies ||= CookieJar.new(@_request, @_response)
      end

      def redirect_to(url, status: 302)
        @_response.redirect(url, status)
      end

      def throw(code)
        status(*Http::Status.for_code(code))
        super :halt
      end

      def status(code, message)
        self.status = code
        self.body   = message
      end

      private
      def _rescue
        catch :halt do
          begin
            yield
          rescue
            throw 500
          end
        end
      end
    end
  end
end
