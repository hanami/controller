# frozen_string_literal: true

module Hanami
  class Action
    # Base class for all Action errors.
    #
    # @api public
    # @since 2.0.0
    class Error < ::StandardError
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
  end
end
