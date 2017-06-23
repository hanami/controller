require 'hanami/action/flash'

module Hanami
  class Action
    # Session API
    #
    # This module isn't included by default.
    #
    # @since 0.1.0
    module Session
      private

      # Container useful to transport data with the HTTP session
      #
      # @return [Hanami::Action::Flash] a Flash instance
      #
      # @since 0.3.0
      #
      # @see Hanami::Action::Flash
      def flash
        @flash ||= Flash.new(response.session, request.id)
      end

      # Finalize the response
      #
      # @return [void]
      #
      # @since 0.3.0
      # @api private
      #
      # @see Hanami::Action#finish
      def finish(req, res, *)
        flash.clear
        res[:session] = res.session
        res[:flash]   = flash
        super
      end
    end
  end
end
