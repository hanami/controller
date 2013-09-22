require 'rack/request'

module Lotus
  module HTTP
    class Request < ::Rack::Request
      HTTP_ACCEPT = 'HTTP_ACCEPT'.freeze

      # TODO order according mime type weight (eg. q=0.8)
      def accept
        if _accept = env[HTTP_ACCEPT]
          _accept.split(',').first
        else
          '*/*'
        end
      end

      # FIXME I don't have the time to fix this hack now.
      # FIXME I'm not sure I want to use this API at all.
      def accepts
        accept == '*/*' ? nil : accept
      end
    end
  end
end
