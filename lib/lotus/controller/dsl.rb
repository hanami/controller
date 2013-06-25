module Lotus
  module Controller
    module Dsl
      class Action
        include ::Lotus::Action
      end

      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
        def action(name, &blk)
          const_set(name, Class.new(Action, &blk))
        end
      end
    end
  end
end
