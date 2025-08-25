# frozen_string_literal: true

module RSpec
  module Support
    module Rack
      # Given a string HTTP header, respond with a header name compatible with current Rack version
      def rack_header(http_header)
        if Hanami::Action.rack_3?
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
