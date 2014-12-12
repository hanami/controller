require 'rack/utils'

module Lotus
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
      ALL = ::Rack::Utils::HTTP_STATUS_CODES.dup.merge({
        103 => 'Checkpoint',
        122 => 'Request-URI too long',
        413 => 'Payload Too Large',                            # Rack 1.5 compat
        414 => 'URI Too Long',                                 # Rack 1.5 compat
        416 => 'Range Not Satisfiable',                        # Rack 1.5 compat
        418 => 'I\'m a teapot',
        420 => 'Enhance Your Calm',
        444 => 'No Response',
        449 => 'Retry With',
        450 => 'Blocked by Windows Parental Controls',
        451 => 'Wrong Exchange server',
        499 => 'Client Closed Request',
        506 => 'Variant Also Negotiates',                      # Rack 1.5 compat
        598 => 'Network read timeout error',
        599 => 'Network connect timeout error'
      }).freeze

      # Status codes that by RFC must not include a message body
      #
      # @api private
      WITHOUT_BODY = Set.new((100..199).to_a << 204 << 205 << 301 << 302 << 304).freeze

      # Return a status for the given code
      #
      # @param code [Fixnum] a valid HTTP code
      #
      # @return [Array] a pair of code and message for an HTTP status
      #
      # @since 0.1.0
      # @api private
      #
      # @example
      #   require 'lotus/http/status'
      #
      #   Lotus::Http::Status.for_code(418) # => [418, "I'm a teapot"]
      def self.for_code(code)
        ALL.assoc(code)
      end

      # Checks if the given code by RFC must not include a message body
      #
      # @param code [Fixnum] a valid HTTP code
      # @return [Boolean] true if the code requires no body
      #
      # @since 0.1.0
      # @api private
      def self.requires_no_body?(code)
        WITHOUT_BODY.include?(code)
      end
    end
  end
end
