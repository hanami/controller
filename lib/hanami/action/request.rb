# frozen_string_literal: true

require "rack/mime"
require "rack/request"
require "rack/utils"
require "securerandom"
require_relative "errors"

module Hanami
  class Action
    # The HTTP request for an action, given to {Action#handle}.
    #
    # Inherits from `Rack::Request`, providing compatibility with Rack functionality.
    #
    # @see http://www.rubydoc.info/gems/rack/Rack/Request
    #
    # @since 0.3.1
    class Request < ::Rack::Request
      # Returns the request's params.
      #
      # @return [Params]
      #
      # @since 2.0.0
      # @api public
      attr_reader :params

      # @since 2.0.0
      # @api private
      def initialize(env:, params:, default_tld_length: 1, session_enabled: false)
        super(env)

        @params = params
        @session_enabled = session_enabled
        @default_tld_length = default_tld_length
      end

      # Returns the request's ID
      #
      # @return [String]
      #
      # @since 2.0.0
      # @api public
      def id
        # FIXME: make this number configurable and document the probabilities of clashes
        @id ||= @env[Action::REQUEST_ID] = SecureRandom.hex(Action::DEFAULT_ID_LENGTH)
      end

      # Returns true if the session is enabled for the request.
      #
      # @return [Boolean]
      #
      # @api public
      # @since 2.1.0
      def session_enabled?
        @session_enabled
      end

      # Returns the session for the request.
      #
      # @return [Hanami::Request::Session] the session object
      #
      # @raise [MissingSessionError] if the session is not enabled
      #
      # @see #session_enabled?
      # @see Response#session
      #
      # @since 2.0.0
      # @api public
      def session
        unless session_enabled?
          raise Hanami::Action::MissingSessionError.new("Hanami::Action::Request#session")
        end

        @session ||= Session.new(super)
      end

      # Returns the flash for the request.
      #
      # @return [Flash]
      #
      # @raise [MissingSessionError] if sessions are not enabled
      #
      # @see Response#flash
      #
      # @since 2.0.0
      # @api public
      def flash
        unless session_enabled?
          raise Hanami::Action::MissingSessionError.new("Hanami::Action::Request#flash")
        end

        @flash ||= Flash.new(session[Flash::KEY])
      end

      # Returns the subdomains for the current host.
      #
      # @return [Array<String>]
      #
      # @api public
      # @since 2.3.0
      def subdomains(tld_length = @default_tld_length)
        return [] if IP_ADDRESS_HOST_REGEXP.match?(host)

        host.split(".")[0..-(tld_length + 2)]
      end

      IP_ADDRESS_HOST_REGEXP = /\A\d+\.\d+\.\d+\.\d+\z/
      private_constant :IP_ADDRESS_HOST_REGEXP

      # Returns the subdomain for the current host.
      #
      # @return [String]
      #
      # @api public
      # @since 2.3.0
      def subdomain(tld_length = @default_tld_length)
        subdomains(tld_length).join(".")
      end

      # @since 2.0.0
      # @api private
      def accept?(mime_type)
        !!::Rack::Utils.q_values(accept).find do |mime, _|
          ::Rack::Mime.match?(mime_type, mime)
        end
      end

      # @since 2.0.0
      # @api private
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
