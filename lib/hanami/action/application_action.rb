# frozen_string_literal: true

module Hanami
  class Action
    class ApplicationAction < Module
      attr_reader :provider
      attr_reader :application

      def initialize(provider)
        @provider = provider
        @application = provider.respond_to?(:application) ? provider.application : Hanami.application

        define_initialize
        define_view_integration_methods
      end

      def inspect
        "#<#{self.class.name}[#{provider}]>"
      end

      private

      def define_initialize
        resolve_context = method(:resolve_view_context)

        define_method :initialize do |**deps|
          @view_context = deps[:view_context] || resolve_context.()
          super(**deps)
        end
      end

      def define_view_integration_methods
        define_method :build_response do |**options|
          options = options.merge(view_options: method(:view_options))
          super(**options)
        end
        private :build_response

        define_method :view_context do
          @view_context
        end

        define_method :view_options do |req, res|
          {context: view_context&.with(view_context_options(req, res))}.compact
        end
        private :view_options

        define_method :view_context_options do |req, res|
          {request: req, response: res}
        end
        private :view_context_options
      end

      def resolve_view_context
        # TODO: make identifier configurable
        identifier = "view.context"

        if provider.key?(identifier)
          provider[identifier]
        elsif application.key?(identifier)
          application[identifier]
        end
      end
    end
  end
end
