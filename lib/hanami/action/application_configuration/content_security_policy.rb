# frozen_string_literal: true

module Hanami
  class Action
    class ApplicationConfiguration
      # Configuration for Content Security Policy in Hanami applications
      #
      # @since 2.0.0
      class ContentSecurityPolicy
        # @since 2.0.0
        # @api private
        def initialize
          @policy = {
            base_uri: "'self'",
            child_src: "'self'",
            connect_src: "'self'",
            default_src: "'none'",
            font_src: "'self'",
            form_action: "'self'",
            frame_ancestors: "'self'",
            frame_src: "'self'",
            img_src: "'self' https: data:",
            media_src: "'self'",
            object_src: "'none'",
            plugin_types: "application/pdf",
            script_src: "'self'",
            style_src: "'self' 'unsafe-inline' https:"
          }
        end

        # Get a CSP setting
        #
        # @param key [Symbol] the underscored name of the CPS setting
        # @return [String,NilClass] the CSP setting, if any
        #
        # @since 2.0.0
        # @api public
        #
        # @example
        # module MyApp
        #   class Application < Hanami::Application
        #     config.actions.content_security_policy[:base_uri] # => "'self'"
        #   end
        # end
        def [](key)
          @policy.fetch(key, nil)
        end

        # Set a CSP setting
        #
        # @param key [Symbol] the underscored name of the CPS setting
        # @param value [String] the CSP setting value
        #
        # @since 2.0.0
        # @api public
        #
        # @example Replace a default value
        # module MyApp
        #   class Application < Hanami::Application
        #     config.actions.content_security_policy[:plugin_types] = nil
        #   end
        # end
        #
        # @example Append to a default value
        # module MyApp
        #   class Application < Hanami::Application
        #     config.actions.content_security_policy[:script_src] += " https://my.cdn.test"
        #   end
        # end
        def []=(key, value)
          @policy[key] = value
        end

        # @since 2.0.0
        # @api private
        def to_str
          @policy.map do |key, value|
            "#{dasherize(key)} #{value}"
          end.join(";\n")
        end

        private

        # @since 2.0.0
        # @api private
        def dasherize(key)
          key.to_s.gsub("_", "-")
        end
      end
    end
  end
end
