require 'lotus/utils/class_attribute'

module Lotus
  module Action
    module Configurable
      def self.included(base)
        config = Lotus::Controller::Configuration.for(base)

        base.class_eval do
          include Utils::ClassAttribute

          class_attribute :configuration
          self.configuration = config
        end

        config.load!(base)
      end

      protected
      def configuration
        self.class.configuration
      end
    end
  end
end
