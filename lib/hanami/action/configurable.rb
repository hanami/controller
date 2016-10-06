require 'hanami/utils/class_attribute'

module Hanami
  module Action
    # Configuration API
    #
    # @since 0.2.0
    #
    # @see Hanami::Controller::Configuration
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
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #   end
      #
      #   Show.configuration
      def self.prepended(base)
        config = Hanami::Controller::Configuration.for(base)

        base.class_eval do
          extend ClassMethods
          include Utils::ClassAttribute

          class_attribute :configuration
          self.configuration = config
        end

        config.copy!(base)
      end

      module ClassMethods
        private

        def configure(&blk)
          self.configuration = configuration.configure(&blk)
          nil
        end
      end

      def initialize(configuration: self.class.configuration, **args)
        super(**args)
        @configuration = Hanami::Controller::Configuration.fabricate(configuration)
      end

      private

      attr_reader :configuration
    end
  end
end
