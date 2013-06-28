require 'lotus/utils/class_attribute'
require 'lotus/utils/callbacks'

module Lotus
  module Action
    module Callbacks
      def self.included(base)
        base.class_eval do
          extend  ClassMethods
          prepend InstanceMethods
        end
      end

      module ClassMethods
        def self.extended(base)
          base.class_eval do
            include Utils::ClassAttribute

            class_attribute :before_callbacks
            self.before_callbacks = Utils::Callbacks::Chain.new

            class_attribute :after_callbacks
            self.after_callbacks = Utils::Callbacks::Chain.new
          end
        end

        def before(*callbacks, &blk)
          before_callbacks.add *callbacks, &blk
        end

        def after(*callbacks, &blk)
          after_callbacks.add *callbacks, &blk
        end
      end

      module InstanceMethods
        def call(params)
          _run_before_callbacks(params)
          super
          _run_after_callbacks(params)
        end

        private
        def _run_before_callbacks(params)
          self.class.before_callbacks.run(self, params)
        end

        def _run_after_callbacks(params)
          self.class.after_callbacks.run(self, params)
        end
      end
    end
  end
end
