# frozen_string_literal: true

require_relative 'action'
require 'hanami/utils/class_attribute'

module Hanami
  class ApplicationAction < Action
    include Utils::ClassAttribute

    attr_reader :view, :view_context, :routes

    def initialize(view: resolve_paired_view, view_context: resolve_view_context, routes: resolve_routes, **dependencies)
      # Conditionally assign these to repsect any explictly auto-injected
      # dependencies provided by the class
      @view = view
      @view_context = view_context
      @routes = routes

      super(**dependencies)
    end

    def self.inherited(action_class)
      raise ArgumentError, "ApplicationAction must be defined within a Hanami::Application" unless Hanami.application?

      super

      Hanami.application.config.tap do |application_config|
        configure_action(action_class.config, application_config)
        extend_behavior(action_class, application_config)
      end
    end

    def provider
      if Hanami.respond_to?(:application?) && Hanami.application?
        Hanami.application.component_provider(self.class)
      end
    end

    def application
      provider.respond_to?(:application) ? provider.application : Hanami.application
    end

    def inspect
      "#<#{self.class.name}[#{self.provider.name}]>"
    end

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
      res.render(view, **req.params) if render?(res)
      super
    end

    # Decide whether to render the current response with the associated view.
    # This can be overridden to enable/disable automatic rendering.
    #
    # @param res [Hanami::Action::Response]
    #
    # @return [TrueClass,FalseClass]
    #
    # @since 2.0.0
    # @api public
    def render?(res)
      view && res.body.empty?
    end

    private

    def resolve_paired_view
      view_identifiers = application.config.actions.view_name_inferrer.call(
        action_name: self.class.name,
        provider: provider
      )

      view_identifiers.detect do |identifier|
        break provider[identifier] if provider.key?(identifier)
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

    def resolve_routes
      application[:routes_helper] if application.key?(:routes_helper)
    end

    def self.configure_action(action_config, application_config)
      action_config.settings.each do |setting|
        application_value = application_config.actions.public_send(:"#{setting}")
        action_config.public_send :"#{setting}=", application_value
      end
    end

    def self.extend_behavior(action_class, application_config)
      if application_config.actions.sessions.enabled?
        require "hanami/action/session"
        action_class.include Hanami::Action::Session
      end

      if application_config.actions.csrf_protection
        require "hanami/action/csrf_protection"
        action_class.include Hanami::Action::CSRFProtection
      end

      if application_config.actions.cookies.enabled?
        require "hanami/action/cookies"
        action_class.include Hanami::Action::Cookies
      end
    end
  end
end
