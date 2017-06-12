require 'rack/request'

module Hanami
  class Action
    # An HTTP request based on top of Rack::Request.
    # This guarantees backwards compatibility with with Rack.
    #
    # @since 0.3.1
    #
    # @see http://www.rubydoc.info/gems/rack/Rack/Request
    class Request < ::Rack::Request
      HTTP_ACCEPT = "HTTP_ACCEPT".freeze
      DEFAULT_ACCEPT = "*/*".freeze

      attr_reader :params

      def initialize(env, params)
        super(env)
        @params = params
      end

      def accept?(mime_type)
        !!::Rack::Utils.q_values(accept).find do |mime, _|
          ::Rack::Mime.match?(mime_type, mime)
        end
      end

      def accept_header?
        accept != DEFAULT_ACCEPT
      end

      # @since 0.1.0
      # @api private
      def accept
        @accept ||= @env[HTTP_ACCEPT] || DEFAULT_ACCEPT
      end

      # @raise [NotImplementedError]
      #
      # @since 0.3.1
      # @api private
      def content_type
        raise NotImplementedError, 'Please use Action#content_type'
      end

      # @raise [NotImplementedError]
      #
      # @since 0.3.1
      # @api private
      def session
        raise NotImplementedError, 'Please include Action::Session and use Action#session'
      end

      # @raise [NotImplementedError]
      #
      # @since 0.3.1
      # @api private
      def cookies
        raise NotImplementedError, 'Please include Action::Cookies and use Action#cookies'
      end

      # @raise [NotImplementedError]
      #
      # @since 0.3.1
      # @api private
      def update_param(*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end

      # @raise [NotImplementedError]
      #
      # @since 0.3.1
      # @api private
      def delete_param(*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end

      # @raise [NotImplementedError]
      #
      # @since 0.3.1
      # @api private
      def [](*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end

      # @raise [NotImplementedError]
      #
      # @since 0.3.1
      # @api private
      def []=(*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end

      # @raise [NotImplementedError]
      #
      # @since 0.3.1
      # @api private
      def values_at(*)
        raise NotImplementedError, 'Please use params passed to Action#call'
      end
    end
  end
end
