# frozen_string_literal: true

require_relative "application_configuration/cookies"
require_relative "application_configuration/sessions"
require_relative "application_configuration/content_security_policy"
require_relative "configuration"
require_relative "view_name_inferrer"

module Hanami
  class Action
    class ApplicationConfiguration
      include Dry::Configurable

      setting :cookies, default: {}, constructor: -> options { Cookies.new(options) }
      setting :sessions, constructor: proc { |storage, *options| Sessions.new(storage, *options) }
      setting :csrf_protection

      setting :content_security_policy, constructor: -> (value) { value === false ? value : ContentSecurityPolicy.new }

      setting :name_inference_base, default: "actions"
      setting :view_context_identifier, default: "view.context"
      setting :view_name_inferrer, default: ViewNameInferrer
      setting :view_name_inference_base, default: "views"

      def initialize(*)
        super

        @base_configuration = Configuration.new

        configure_defaults
      end

      def finalize!
        # A nil value for `csrf_protection` means it has not been explicitly configured
        # (neither true nor false), so we can default it to whether sessions are enabled
        self.csrf_protection = sessions.enabled? if csrf_protection.nil?

        if self.content_security_policy
          self.default_headers["Content-Security-Policy"] = self.content_security_policy.to_str
        end
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
          "X-XSS-Protection" => "1; mode=block"
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
