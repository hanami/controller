module Lotus
  module Action
    # Ensures to not send body or headers for HEAD requests and/or for status
    # codes that doesn't allow them.
    #
    # @since x.x.x
    #
    # @see http://www.ietf.org/rfc/rfc2616.txt
    module Head

      # Status codes that by RFC must not include a message body
      #
      # @since x.x.x
      # @api private
      HTTP_STATUSES_WITHOUT_BODY = Set.new((100..199).to_a << 204 << 304).freeze

      # Ensures to not send body or headers for HEAD requests and/or for status
      # codes that doesn't allow them.
      #
      # @since x.x.x
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
      # @since x.x.x
      # @api private
      def _requires_no_body?
        HTTP_STATUSES_WITHOUT_BODY.include?(@_status) || head?
      end
    end
  end
end
