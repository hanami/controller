# frozen_string_literal: true

require_relative "configuration"

module Hanami
  class Action
    class ApplicationConfiguration
      include Dry::Configurable

      setting :view_context_identifier, "view.context"

      Configuration._settings.each do |action_setting|
        _settings << action_setting.dup
      end

      def initialize(*)
        super

        config.default_request_format = :html
        config.default_response_format = :html
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
