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

        define_initialize
        configure_action action_class
        extend_behavior action_class
      end

      def inspect
        "#<#{self.class.name}[#{provider.name}]>"
      end

      private

      def define_initialize
        resolve_view = method(:resolve_paired_view)
        resolve_context = method(:resolve_view_context)
        resolve_routes = method(:resolve_routes)

        define_method :initialize do |**deps|
          # Conditionally assign these to repsect any explictly auto-injected
          # dependencies provided by the class
          @view ||= deps[:view] || resolve_view.(self.class)
          @view_context ||= deps[:view_context] || resolve_context.()
          @routes ||= deps[:routes] || resolve_routes.()

          super(**deps)
        end
      end

      def resolve_paired_view(action_class)
        view_identifiers = application.config.actions.view_name_inferrer.(
          action_name: action_class.name,
          provider: provider
        )

        view_identifiers.detect { |identifier|
          break provider[identifier] if provider.key?(identifier)
        }
      end

      def resolve_view_context
        identifier = application.config.actions.view_context_identifier

        if provider.key?(identifier)
          provider[identifier]
        elsif application.key?(identifier)
          application[identifier]
        end
      end

      def resolve_routes
        application[:routes_helper] if application.key?(:routes_helper)
      end

      def configure_action(action_class)
        action_class.config.settings.each do |setting|
          application_value = application.config.actions.public_send(:"#{setting}")
          action_class.config.public_send :"#{setting}=", application_value
        end
      end

      def extend_behavior(action_class)
        if application.config.actions.sessions.enabled?
          require "hanami/action/session"
          action_class.include Hanami::Action::Session
        end

        if application.config.actions.csrf_protection
          require "hanami/action/csrf_protection"
          action_class.include Hanami::Action::CSRFProtection
        end

        if application.config.actions.cookies.enabled?
          require "hanami/action/cookies"
          action_class.include Hanami::Action::Cookies
        end
      end

      module InstanceMethods
        attr_reader :view
        attr_reader :view_context
        attr_reader :routes

        def build_response(**options)
          options = options.merge(view_options: method(:view_options))
          super(**options)
        end

        def view_options(req, res)
          {context: view_context&.with(**view_context_options(req, res))}.compact
        end

        def view_context_options(req, res)
          {request: req, response: res}
        end

        def finish(req, res, halted)
          result = super
          res.render(view, **req.params) if render?(res)
          result
        end

        # Decide whether to render the current response with the associated view.
        # This can be overridden to enable/disable automatic rendering.
        #
        # @param response [Hanami::Action::Response]
        #
        # @return [TrueClass,FalseClass]
        #
        # @since 2.0.0
        # @api public
        def render?(res)
          view && res.body.empty?
        end
      end
    end
  end
end
