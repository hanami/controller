# frozen_string_literal: true

require "dry/configurable"
require "hanami/utils/string"

module Hanami
  class Action
    class ApplicationConfiguration
      # Configuration for HTTP sessions in Hanami actions
      #
      # @since 2.0.0
      class Security
        include Dry::Configurable

        setting :x_frame_options, "DENY"

        setting :x_content_type_options, "nosniff"

        setting :x_xss_protection, "1; mode=block"

        setting :content_security_policy, {
          form_action: "'self'",
          frame_ancestors: "'self'",
          base_uri: "'self'",
          default_src: "'none'",
          script_src: "'self'",
          connect_src: "'self'",
          img_src: "'self' https: data:",
          style_src: "'self' 'unsafe-inline' https:",
          font_src: "'self'",
          object_src: "'none'",
          plugin_types: "application/pdf",
          child_src: "'self'",
          frame_src: "'self'",
          media_src: "'self'"
        }.freeze

        # Returns the list of available settings
        #
        # @return [Set]
        #
        # @since 2.0.0
        # @api private
        def settings
          self.class.settings
        end

        def to_headers
          {
            "X-Frame-Options" => config.x_frame_options,
            "X-Content-Type-Options" => config.x_content_type_options,
            "X-XSS-Protection" => config.x_xss_protection,
            "Content-Security-Policy" => config.content_security_policy
              .compact
              .map { |key, val| "#{Utils::String.dasherize(key)} #{val}" }
              .join("; ")
          }.compact
        end

        private

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
end
