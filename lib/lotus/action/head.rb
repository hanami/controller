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


      # Entity headers allowed in blank body responses, according to
      # RFC 2616 - Section 10 (HTTP 1.1).
      #
      # "The response MAY include new or updated metainformation in the form
      #   of entity-headers".
      #
      # @since 0.4.0
      # @api private
      #
      # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html#sec10.2.5
      # @see http://www.w3.org/Protocols/rfc2616/rfc2616-sec7.html
      ENTITY_HEADERS = {
        'Allow'            => true,
        'Content-Encoding' => true,
        'Content-Language' => true,
        'Content-Location' => true,
        'Content-MD5'      => true,
        'Content-Range'    => true,
        'Expires'          => true,
        'Last-Modified'    => true,
        'extension-header' => true
      }.freeze

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
          @headers.reject! { |header,_| !ENTITY_HEADERS.include?(header) }
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
