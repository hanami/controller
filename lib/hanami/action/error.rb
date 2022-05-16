module Hanami
  class Action
    # @since 2.0.0
    class Error < ::StandardError
    end

    # @since 2.0.0
    class NotImplementedError < Error
    end
  end
end
