# frozen_string_literal: true

require_relative "configuration"
require_relative "view_name_inferrer"

module Hanami
  class Action
    class ApplicationConfiguration
      include Dry::Configurable

      setting :csrf_protection
      setting :name_inference_base, "actions"
      setting :view_context_identifier, "view.context"
      setting :view_name_inferrer, ViewNameInferrer
      setting :view_name_inference_base, "views"

      Configuration._settings.each do |action_setting|
        _settings << action_setting.dup
      end

      def initialize(application_config, *args)
        super(*args)

        @application_config = application_config

        # Adjust defaults for base configuration
        config.default_request_format = :html
        config.default_response_format = :html
      end

      def finalize!
        # A nil value for `csrf_protection` means it has not been explicitly configured
        # (neither true nor false), so we can defaut it to whether sessions are enabled
        if config.csrf_protection.nil?
          config.csrf_protection = application_config.sessions.enabled?
        end
      end

      # Returns the list of available settings
      #
      # @return [Set]
      #
      # @since 2.0.0
      # @api private
      def settings
        self.class.settings
      end

      private

      attr_reader :application_config

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
