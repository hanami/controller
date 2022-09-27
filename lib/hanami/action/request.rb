# frozen_string_literal: true

require "rack/utils"
require "rack/mime"
require "rack/request"
require "securerandom"

module Hanami
  class Action
    # An HTTP request based on top of Rack::Request.
    # This guarantees backwards compatibility with with Rack.
    #
    # @since 0.3.1
    #
    # @see http://www.rubydoc.info/gems/rack/Rack/Request
    class Request < ::Rack::Request
      attr_reader :params

      def initialize(env, params)
        super(env)
        @params = params
      end

      def id
        # FIXME: make this number configurable and document the probabilities of clashes
        @id ||= @env[Action::REQUEST_ID] = SecureRandom.hex(Action::DEFAULT_ID_LENGTH)
      end

      def accept?(mime_type)
        !!::Rack::Utils.q_values(accept).find do |mime, _|
          ::Rack::Mime.match?(mime_type, mime)
        end
      end

      def accept_header?
        accept != Action::DEFAULT_ACCEPT
      end

      # @since 0.1.0
      # @api private
      def accept
        @accept ||= @env[Action::HTTP_ACCEPT] || Action::DEFAULT_ACCEPT
      end
    end
  end
end
