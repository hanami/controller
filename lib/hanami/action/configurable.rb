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
        base.class_eval do
          prepend InstanceMethods
        end
      end

      module InstanceMethods
        def initialize(configuration:, **args)
          super(**args)
          @configuration = configuration

          # MIME Types
          @accepted_mime_types = @configuration.restrict_mime_types(
              self.class.accepted_formats.map do |format|
                format_to_mime_type(format)
              end
            )

          @accepted_mime_types = nil if @accepted_mime_types.empty?

          # Exceptions
          @handled_exceptions = @configuration.handled_exceptions.merge(self.class.handled_exceptions)
          @handled_exceptions = Hash[
            @handled_exceptions.sort{|(ex1,_),(ex2,_)| ex1.ancestors.include?(ex2) ? -1 : 1 }
          ]

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
