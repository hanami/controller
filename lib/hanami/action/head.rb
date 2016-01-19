module Hanami
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
      # @see Hanami::Action#finish
      def finish
        super

        if _requires_no_body?
          @_body = nil
          @headers.reject! {|header,_| !keep_response_header?(header) }
        end
      end

      protected
      # @since 0.3.2
      # @api private
      def _requires_no_body?
        HTTP_STATUSES_WITHOUT_BODY.include?(@_status) || head?
      end

      private
      # According to RFC 2616, when a response MUST have an empty body, it only
      # allows Entity Headers.
      #
      # For instance, a <tt>204</tt> doesn't allow <tt>Content-Type</tt> or any
      # other custom header.
      #
      # This restriction is enforced by <tt>Hanami::Action::Head#finish</tt>.
      #
      # However, there are cases that demand to bypass this rule to set meta
      # informations via headers.
      #
      # An example is a <tt>DELETE</tt> request for a JSON API application.
      # It returns a <tt>204</tt> but still wants to specify the rate limit
      # quota via <tt>X-Rate-Limit</tt>.
      #
      # @since 0.5.0
      # @api public
      #
      # @see Hanami::Action::HEAD#finish
      #
      # @example
      #   require 'hanami/controller'
      #
      #   module Books
      #     class Destroy
      #       include Hanami::Action
      #
      #       def call(params)
      #         # ...
      #         self.headers.merge!(
      #           'Last-Modified' => 'Fri, 27 Nov 2015 13:32:36 GMT',
      #           'X-Rate-Limit'  => '4000',
      #           'Content-Type'  => 'application/json',
      #           'X-No-Pass'     => 'true'
      #         )
      #
      #         self.status = 204
      #       end
      #
      #       private
      #
      #       def keep_response_header?(header)
      #         super || header == 'X-Rate-Limit'
      #       end
      #     end
      #   end
      #
      #   # Only the following headers will be sent:
      #   #  * Last-Modified - because we used `super' in the method that respects the HTTP RFC
      #   #  * X-Rate-Limit  - because we explicitely allow it
      #
      #   # Both Content-Type and X-No-Pass are removed because they're not allowed
      def keep_response_header?(header)
        ENTITY_HEADERS.include?(header)
      end
    end
  end
end
