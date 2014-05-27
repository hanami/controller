require 'lotus/utils/class_attribute'

module Lotus
  module Action
    module Configurable
      def self.included(base)
        base.class_eval do
          include Utils::ClassAttribute

          class_attribute :configuration
          self.configuration ||= Controller.configuration.duplicate
        end
      end

      protected
      def configuration
        self.class.configuration
      end
    end
  end
end
