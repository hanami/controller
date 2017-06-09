require 'rack'
require 'rack/response'

module Hanami
  class Action
    class Response < ::Rack::Response
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
    end
  end
end
