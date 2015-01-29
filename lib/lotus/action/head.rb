module Lotus
  module Action
    # Ensures to not send body or headers for HEAD requests and/or for status
    # codes that doesn't allow them.
    #
    # @since 0.3.2
    #
    # @see http://www.ietf.org/rfc/rfc2616.txt
    module Head

      # Status codes that by RFC must not include a message body
      #
      # @since 0.3.2
      # @api private
      HTTP_STATUSES_WITHOUT_BODY = Set.new((100..199).to_a << 204 << 205 << 304).freeze

      # Ensures to not send body or headers for HEAD requests and/or for status
      # codes that doesn't allow them.
      #
      # @since 0.3.2
      # @api private
      #
      # @see Lotus::Action#finish
      def finish
        super

        if _requires_no_body?
          @_body = nil
        end
      end

      protected
      # @since 0.3.2
      # @api private
      def _requires_no_body?
        HTTP_STATUSES_WITHOUT_BODY.include?(@_status) || head?
      end
    end
  end
end
