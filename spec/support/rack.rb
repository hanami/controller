# frozen_string_literal: true

module RSpec
  module Support
    module Rack
      # Determines if the current Rack environment is version 3 or higher.
      def rack3?
        defined?(::Rack::Headers)
      end

      # Given a string HTTP header, respond with a header name compatible with current Rack version
      def rack_header(http_header)
        if rack3?
          http_header.downcase
        else
          http_header
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpec::Support::Rack
end
