# frozen_string_literal: true

module Hanami
  class Action
    # @since 2.0.0
    class Error < ::StandardError
    end

    # Missing session error
    #
    # This error is raised when `session` or `flash` is accessed/set on request/response objects
    # in actions which do not include `Hanami::Action::Session`.
    #
    # @since 2.0.0
    #
    # @see Hanami::Action::Session
    # @see Hanami::Action::Request#session
    # @see Hanami::Action::Response#session
    # @see Hanami::Action::Response#flash
    class MissingSessionError < Error
      def initialize(session_method)
        super("To use `#{session_method}`, add `include Hanami::Action::Session`.")
      end
    end
  end
end
