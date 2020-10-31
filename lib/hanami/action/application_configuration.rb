# frozen_string_literal: true

require_relative "application_configuration/sessions"
require_relative "configuration"
require_relative "view_name_inferrer"

module Hanami
  class Action
    class ApplicationConfiguration
      include Dry::Configurable

      setting(:sessions) { |storage, *options| Sessions.new(storage, *options) }
      setting :csrf_protection

      setting :name_inference_base, "actions"
      setting :view_context_identifier, "view.context"
      setting :view_name_inferrer, ViewNameInferrer
      setting :view_name_inference_base, "views"

      def initialize(*)
        super

        @base_configuration = Configuration.new

        configure_defaults
      end

      def finalize!
        # A nil value for `csrf_protection` means it has not been explicitly configured
        # (neither true nor false), so we can default it to whether sessions are enabled
        self.csrf_protection = sessions.enabled? if csrf_protection.nil?
      end

      # Returns the list of available settings
      #
      # @return [Set]
      #
      # @since 2.0.0
      # @api private
      def settings
        base_configuration.settings + self.class.settings
      end

      private

      attr_reader :base_configuration

      # Apply defaults for base configuration settings
      def configure_defaults
        self.default_request_format = :html
        self.default_response_format = :html

        self.default_headers = {
          "X-Frame-Options" => "DENY",
          "X-Content-Type-Options" => "nosniff",
          "X-XSS-Protection" => "1; mode=block",
          "Content-Security-Policy" => \
            "base-uri 'self'; " \
            "child-src 'self'; " \
            "connect-src 'self'; " \
            "default-src 'none'; " \
            "font-src 'self'; " \
            "form-action 'self'; " \
            "frame-ancestors 'self'; " \
            "frame-src 'self'; " \
            "img-src 'self' https: data:; " \
            "media-src 'self'; " \
            "object-src 'none'; " \
            "plugin-types application/pdf; " \
            "script-src 'self'; " \
            "style-src 'self' 'unsafe-inline' https:"
        }
      end

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        elsif base_configuration.respond_to?(name)
          base_configuration.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || base_configuration.respond_to?(name) || super
      end
    end
  end
end
