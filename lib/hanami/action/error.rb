module Hanami
  class Action
    # @since 2.0.0
    class Error < ::StandardError
    end

    # Missing session error
    #
    # This error is raised when an action sends either `session` or `flash` to
    # itself and it does not include `Hanami::Action::Session`.
    #
    # @since 2.0.0
    #
    # @see Hanami::Action::Session
    # @see Hanami::Action#session
    # @see Hanami::Action#flash
    class MissingSessionError < Error
      def initialize(session_method)
        super("To use `#{session_method}', add `include Hanami::Action::Session`.")
      end
    end
  end
end
