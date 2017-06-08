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
      def self.included(base)
        config = Hanami::Controller::Configuration.for(base)

        base.class_eval do
          prepend InstanceMethods
          include Utils::ClassAttribute

          class_attribute :configuration
          self.configuration = config
        end

        config.copy!(base)
      end

      module InstanceMethods
        def initialize(configuration: self.class.configuration, **args)
          super(**args)
          @configuration = configuration
          # FIXME: this has to be removed when Hanami::Controller.finalize is implemented
          @configuration.copy!(self.class)
        end
      end

      private

      # @since 0.2.0
      attr_reader :configuration
    end
  end
end
