module Lotus
  module Controller
    module Dsl
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
        def action(name, &blk)
          const_set(name, Class.new)

          const_get(name).tap do |klass|
            klass.class_eval { include ::Lotus::Action }
            klass.class_eval(&blk)
          end
        end
      end
    end
  end
end
