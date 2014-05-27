module Lotus
  module Controller
    class Configuration
      DEFAULT_ERROR_CODE = 500

      def initialize
        reset!
      end

      attr_accessor :handled_exceptions
      attr_writer :handle_exceptions, :action_module

      def handle_exceptions(value = nil)
        if value.nil?
          @handle_exceptions
        else
          @handle_exceptions = value
        end
      end

      def handle_exception(exception)
        @handled_exceptions.merge!(exception)
      end

      def exception_code(exception)
        @handled_exceptions.fetch(exception) { DEFAULT_ERROR_CODE }
      end

      def action_module(value = nil)
        if value.nil?
          @action_module
        else
          @action_module = value
        end
      end

      def duplicate
        Configuration.new.tap do |c|
          c.handle_exceptions  = handle_exceptions
          c.handled_exceptions = handled_exceptions.dup
          c.action_module      = action_module
        end
      end

      def reset!
        @handle_exceptions  = true
        @handled_exceptions = {}
        @action_module      = ::Lotus::Action
      end
    end
  end
end
