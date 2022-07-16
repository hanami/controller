# frozen_string_literal: true

require "rack/utils"

module Hanami
  module Http
    # An HTTP status
    #
    # @since 0.1.0
    # @api private
    class Status
      # A set of standard codes and messages for HTTP statuses
      #
      # @since 0.1.0
      # @api private
      ALL = ::Rack::Utils::HTTP_STATUS_CODES

      # Returns a status for the given code
      #
      # @param code [Integer] a valid HTTP code
      #
      # @return [Array] a pair of code and message for an HTTP status
      #
      # @since 0.1.0
      # @api private
      #
      # @example
      #   require 'hanami/http/status'
      #
      #   Hanami::Http::Status.for_code(409) # => [409, "Conflict"]
      def self.for_code(code)
        ALL.assoc(code)
      end

      # Returns a message for the given status code
      #
      # @param code [Integer] a valid HTTP code
      #
      # @return [String] a message for the given status code
      #
      # @since 0.3.2
      # @api private
      #
      # @example
      #   require 'hanami/http/status'
      #
      #   Hanami::Http::Status.message_for(409) # => "Conflict"
      def self.message_for(code)
        for_code(code)[1]
      end
    end
  end
end
