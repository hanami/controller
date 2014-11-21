require 'lotus/utils/class_attribute'

module Lotus
  module Action
    # Configuration API
    #
    # @since 0.2.0
    #
    # @see Lotus::Controller::Configuration
    module Configurable
      # Override Ruby's hook for modules.
      # It includes configuration logic
      #
      # @param base [Class] the target action
      #
      # @since 0.2.0
      # @api private
      #
      # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
      #
      # @example
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #   end
      #
      #   Show.configuration
      def self.included(base)
        config = Lotus::Controller::Configuration.for(base)

        base.class_eval do
          include Utils::ClassAttribute

          class_attribute :configuration
          self.configuration = config
        end

        config.copy!(base)
      end

      private

      def configuration
        self.class.configuration
      end
    end
  end
end
