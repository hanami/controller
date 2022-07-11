# frozen_string_literal: true

require "hanami/action/flash"

module Hanami
  class Action
    # Session API
    #
    # This module isn't included by default.
    #
    # @since 0.1.0
    module Session
      def self.included(base)
        base.class_eval do
          before { |req, _| req.id }
        end
      end

      private

      # Finalize the response
      #
      # @return [void]
      #
      # @since 0.3.0
      # @api private
      #
      # @see Hanami::Action#finish
      def finish(req, res, *)
        if (next_flash = res.flash.next).any?
          res.session[Flash::KEY] = next_flash
        else
          res.session.delete(Flash::KEY)
        end

        super
      end
    end
  end
end
