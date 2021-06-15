require "hanami/http/status"

module Hanami
  class Action
    module Halt
      def self.call(status, body = nil)
        body ||= Http::Status.message_for(status)
        throw :halt, [status, body]
      end
    end
  end
end
