# frozen_string_literal: true

module Hanami
  class Action
    # Cache type API
    #
    # @since 0.3.0
    # @api private
    #
    # @see Hanami::Action::Response#cache_control
    # @see Hanami::Action::Response#expires
    # @see Hanami::Action::Response#fresh
    module Cache
      # Override Ruby's hook for modules.
      # It includes exposures logic
      #
      # @param base [Class] the target action
      #
      # @since 0.3.0
      # @api private
      #
      # @see http://www.ruby-doc.org/core/Module.html#method-i-included
      def self.included(base)
        base.class_eval do
          include CacheControl, Expires
        end
      end
    end
  end
end
