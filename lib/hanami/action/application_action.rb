# frozen_string_literal: true

module Hanami
  class Action
    class ApplicationAction < Module
      attr_reader :provider
      attr_reader :application

      def initialize(provider)
        @provider = provider
        @application = provider.respond_to?(:application) ? provider.application : Hanami.application
      end

      def included(action_class)
        action_class.include InstanceMethods

        define_initialize action_class
        configure_action action_class
      end

      def inspect
        "#<#{self.class.name}[#{provider.name}]>"
      end

      private

      def define_initialize(action_class)
        resolve_view = method(:resolve_paired_view)
        resolve_context = method(:resolve_view_context)

        define_method :initialize do |**deps|
          super(**deps)
          @view = deps[:view] || resolve_view.(action_class)
          @view_context = deps[:view_context] || resolve_context.()
        end
      end

      def resolve_view_context
        identifier = application.config.actions.view_context_identifier

        if provider.key?(identifier)
          provider[identifier]
        elsif application.key?(identifier)
          application[identifier]
        end
      end

      def resolve_paired_view(action_class)
        view_identifiers = application.config.actions.view_name_inferrer.(
          action_name: action_class.name,
          provider: provider
        )

        view_identifiers.each_with_object(nil) { |identifier|
          break provider[identifier] if provider.key?(identifier)
        }
      end

      def configure_action(action_class)
        action_class.config.settings.each do |setting|
          application_value = application.config.actions.public_send(:"#{setting}")
          action_class.config.public_send :"#{setting}=", application_value
        end
      end

      module InstanceMethods
        # FIXME: Can I turn these into attr_readers?
        def view
          @view
        end

        def view_context
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
