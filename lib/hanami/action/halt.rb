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
        unless (normalized_status = Http::Status.normalize(status))
          raise UnknownStatusCodeError.new(status)
        end

        body ||= Http::Status.message_for(normalized_status)
        throw :halt, [normalized_status, body]
      end
    end
  end
end
