module Lotus
  module Action
    module Rack
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
    end
  end
end
