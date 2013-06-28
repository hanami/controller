module Lotus
  module Utils
    module ClassAttribute
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
        def class_attribute(*names)
          (class << self; self; end).class_eval do
            attr_accessor *names
          end

          @class_attributes ||= Set.new
          @class_attributes.merge(names)
        end

        def inherited(subclass)
          @class_attributes.each do |attr|
            value = send(attr).dup rescue nil
            subclass.send("#{attr}=", value)
          end

          super
        end
      end
    end
  end
end
