# frozen_string_literal: true

require "hanami/action/cache/cache_control"
require "hanami/action/cache/expires"
require "hanami/action/cache/conditional_get"

module Hanami
  class Action
    # Cache type API
    #
    # @since 0.3.0
    #
    # @see Hanami::Action::Cache::CacheControl::ClassMethods#cache_control
    # @see Hanami::Action::Cache::Expires::ClassMethods#expires
    # @see Hanami::Action::Cache::ETag#fresh?
    module Cache
      # Overrides Ruby's hook for modules.
      # It includes exposures logic
      #
      # @param base [Class] the target action
      #
      # @since 0.3.0
      # @api private
      #
      # @see https://www.ruby-doc.org/core/Module.html#method-i-included
      def self.included(base)
        base.class_eval do
          include CacheControl, Expires
        end
      end
    end
  end
end
