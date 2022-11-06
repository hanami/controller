# frozen_string_literal: true

module Hanami
  class Action
    # Base class for all Action errors.
    #
    # @api public
    # @since 2.0.0
    class Error < ::StandardError
    end

    # Unknown format error
    #
    # This error is raised when a action sets a format that it isn't recognized
    # both by `Hanami::Action::Configuration` and the list of Rack mime types
    #
    # @since 2.0.0
    #
    # @see Hanami::Action::Mime#format=
    class UnknownFormatError < Error
      # @since 2.0.0
      # @api private
      def initialize(format)
        super("Cannot find a corresponding Mime type for '#{format}'. Please configure it with Hanami::Controller::Configuration#format.") # rubocop:disable Layout/LineLength
      end
    end

    # Error raised when session is accessed but not enabled.
    #
    # This error is raised when `session` or `flash` is accessed/set on request/response objects
    # in actions which do not include `Hanami::Action::Session`.
    #
    # @see Hanami::Action::Session
    # @see Hanami::Action::Request#session
    # @see Hanami::Action::Response#session
    # @see Hanami::Action::Response#flash
    #
    # @api public
    # @since 2.0.0
    class MissingSessionError < Error
      # @api private
      # @since 2.0.0
      def initialize(session_method)
        super(<<~TEXT)
          Sessions are not enabled. To use `#{session_method}`:

          Configure sessions in your Hanami app, e.g.

            module MyApp
              class App < Hanami::App
                # See Rack::Session::Cookie for options
                config.sessions = :cookie, {**cookie_session_options}
              end
            end

          Or include session support directly in your action class:

            include Hanami::Action::Session
        TEXT
      end
    end

    # Invalid CSRF Token
    #
    # @since 0.4.0
    class InvalidCSRFTokenError < Error
    end
  end
end
