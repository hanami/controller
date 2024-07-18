# frozen_string_literal: true

module Hanami
  class Action
    # Cookies API
    #
    # If you want cookies in your actions then include this module.
    # It's not included by default.
    #
    # @since 0.1.0
    #
    # @see Hanami::Action::Response#cookies
    module Cookies
      private

      # Finalize the response by flushing cookies into the response
      #
      # @since 0.1.0
      # @api private
      #
      # @see Hanami::Action#finish
      def finish(req, res, *)
        res.cookies.finish
        super
      end
    end
  end
end
