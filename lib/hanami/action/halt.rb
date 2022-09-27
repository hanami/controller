# frozen_string_literal: true

require "hanami/http/status"

module Hanami
  class Action
    module Halt
      # @since 2.0.0
      # @api private
      def self.call(status, body = nil)
        body ||= Http::Status.message_for(status)
        throw :halt, [status, body]
      end
    end
  end
end
