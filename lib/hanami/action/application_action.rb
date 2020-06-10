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
      end

      def included(klass)
        klass.include InstanceMethods
      end

      def inspect
        "#<#{self.class.name}[#{provider}]>"
      end

      private

      def define_initialize
        resolve_context = method(:resolve_view_context)

        define_method :initialize do |**deps|
          super(**deps)
          @view_context = deps[:view_context] || resolve_context.()
        end
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

      module InstanceMethods
        define_method :view_context do
          @view_context
        end

        private

        def build_response(**options)
          options = options.merge(view_options: method(:view_options))
          super(**options)
        end

        def view_options(req, res)
          {context: view_context&.with(view_context_options(req, res))}.compact
        end

        def view_context_options(req, res)
          {request: req, response: res}
        end
      end
    end
  end
end
