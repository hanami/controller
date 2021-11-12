module Hanami
  module Controller
    # @since 0.5.0
    class Error < ::StandardError
    end

    # Missing view error.
    #
    # It's raised when an ApplicationAction should automatically render a view,
    # but there's no view associated with the instance
    #
    # @since 2.0.0
    class MissingViewError < Error
      def initialize
        super("Cannot render a view that is missing")
      end
    end
  end
end
