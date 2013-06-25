module Lotus
  module Action
    module Exposable
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
        def expose(*names)
          class_eval do
            attr_reader    *names
            exposures.push *names
          end
        end

        def exposures
          @exposures ||= []
        end
      end

      def exposures
        {}.tap do |result|
          self.class.exposures.each do |exposure|
            result[exposure] = send(exposure)
          end
        end
      end
    end
  end
end
