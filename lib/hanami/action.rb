require_relative 'action/standalone_action'

module Hanami
  # An HTTP endpoint
  #
  # @since 0.1.0
  #
  # @example
  #   require 'hanami/controller'
  #
  #   class Show
  #     include Hanami::Action
  #
  #     def call(params)
  #       # ...
  #     end
  #   end
  class Action
    # Rack SPEC response code
    #
    # @since 1.0.0
    # @api private
    RESPONSE_CODE = 0

    # Rack SPEC response headers
    #
    # @since 1.0.0
    # @api private
    RESPONSE_HEADERS = 1

    # Rack SPEC response body
    #
    # @since 1.0.0
    # @api private
    RESPONSE_BODY = 2

    DEFAULT_ERROR_CODE = 500

    # Status codes that by RFC must not include a message body
    #
    # @since 0.3.2
    # @api private
    HTTP_STATUSES_WITHOUT_BODY = Set.new((100..199).to_a << 204 << 205 << 304).freeze

    # Not Found
    #
    # @since 1.0.0
    # @api private
    NOT_FOUND = 404

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

    # The request method
    #
    # @since 0.3.2
    # @api private
    REQUEST_METHOD = 'REQUEST_METHOD'.freeze

    # The Content-Length HTTP header
    #
    # @since 1.0.0
    # @api private
    CONTENT_LENGTH = 'Content-Length'.freeze

    # The non-standard HTTP header to pass the control over when a resource
    # cannot be found by the current endpoint
    #
    # @since 1.0.0
    # @api private
    X_CASCADE = 'X-Cascade'.freeze

    # HEAD request
    #
    # @since 0.3.2
    # @api private
    HEAD = 'HEAD'.freeze

    # The key that returns accepted mime types from the Rack env
    #
    # @since 0.1.0
    # @api private
    HTTP_ACCEPT          = 'HTTP_ACCEPT'.freeze

    # The header key to set the mime type of the response
    #
    # @since 0.1.0
    # @api private
    CONTENT_TYPE         = 'Content-Type'.freeze

    # The default mime type for an incoming HTTP request
    #
    # @since 0.1.0
    # @api private
    DEFAULT_ACCEPT       = '*/*'.freeze

    # The default mime type that is returned in the response
    #
    # @since 0.1.0
    # @api private
    DEFAULT_CONTENT_TYPE = 'application/octet-stream'.freeze

    # @since 0.2.0
    # @api private
    RACK_ERRORS = 'rack.errors'.freeze

    # This isn't part of Rack SPEC
    #
    # Exception notifiers use <tt>rack.exception</tt> instead of
    # <tt>rack.errors</tt>, so we need to support it.
    #
    # @since 0.5.0
    # @api private
    #
    # @see Hanami::Action::Throwable::RACK_ERRORS
    # @see http://www.rubydoc.info/github/rack/rack/file/SPEC#The_Error_Stream
    # @see https://github.com/hanami/controller/issues/133
    RACK_EXCEPTION = 'rack.exception'.freeze

    # The HTTP header for redirects
    #
    # @since 0.2.0
    # @api private
    LOCATION = 'Location'.freeze

    include StandaloneAction
  end
end
