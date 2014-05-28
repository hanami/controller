require 'lotus/utils/string'
require 'lotus/utils/class'

module Lotus
  module Controller
    class Configuration
      DEFAULT_ERROR_CODE = 500

      def self.for(base)
        namespace = Utils::String.new(base).namespace
        framework = Utils::Class.load!("(#{namespace}|Lotus)::Controller")
        framework.configuration.duplicate
      end

      def initialize
        reset!
      end

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

      def action_module(value = nil)
        if value.nil?
          @action_module
        else
          @action_module = value
        end
      end

      def modules(&blk)
        if block_given?
          @modules.push(blk)
        else
          @modules
        end
      end

      def duplicate
        Configuration.new.tap do |c|
          c.handle_exceptions  = handle_exceptions
          c.handled_exceptions = handled_exceptions.dup
          c.action_module      = action_module
          c.modules            = modules.dup
        end
      end

      def reset!
        @handle_exceptions  = true
        @handled_exceptions = {}
        @modules            = []
        @action_module      = ::Lotus::Action
      end

      def load!(base)
        modules.each do |mod|
          base.class_eval(&mod)
        end
      end

      protected
      attr_accessor :handled_exceptions
      attr_writer :action_module
      attr_writer :modules
    end
  end
end
