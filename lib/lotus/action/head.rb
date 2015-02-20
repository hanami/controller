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


      # Entity headers that by RFC are permitted
      #
      # @since x.x.x
      # @api private
      ENTITY_HEADERS = {
        'Allow'            => true,
        'Content-Encoding' => true,
        'Content-Language' => true,
        'Content-Length'   => true,
        'Content-Location' => true,
        'Content-MD5'      => true,
        'Content-Range'    => true,
        'Content-Type'     => true,
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
