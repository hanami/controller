# frozen_string_literal: true

require "hanami/http/status"

module Hanami
  class Action
    # @api private
    # @since 2.0.0
    module Halt
      # @api private
      # @since 2.0.0
      def self.call(status, body = nil)
        body ||= Http::Status.message_for(status)
        throw :halt, [status, body]
      end
    end
  end
end
