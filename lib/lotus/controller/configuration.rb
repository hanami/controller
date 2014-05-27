module Lotus
  module Controller
    class Configuration
      DEFAULT_ERROR_CODE = 500

      def initialize
        reset!
      end

      attr_reader :handled_exceptions
      attr_writer :handle_exceptions

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

      def reset!
        @handle_exceptions  = true
        @handled_exceptions = {}
      end
    end
  end
end
