module Lotus
  module Utils
    module Callbacks
      class Chain < Set
        def add(*callbacks, &blk)
          callbacks.push blk if block_given?
          callbacks.each do |c|
            super Callback.fabricate(c)
          end
        end

        def run(context, *args)
          each do |callback|
            callback.call(context, *args)
          end
        end
      end

      class Callback
        attr_reader :callback

        def self.fabricate(callback)
          if callback.respond_to?(:call)
            new(callback)
          else
            MethodCallback.new(callback)
          end
        end

        def initialize(callback)
          @callback = callback
        end

        def call(context, *args)
          context.instance_exec(*args, &callback)
        end
      end

      class MethodCallback < Callback
        def call(context, *args)
          method = context.method(callback)

          if method.parameters.any?
            method.call(*args)
          else
            method.call
          end
        end
      end
    end
  end
end
