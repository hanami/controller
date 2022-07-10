# frozen_string_literal: true

require "delegate"
require_relative "./request"
require_relative "./response"

module Hanami
  class Action
    class Proxy < SimpleDelegator
      def initialize(action)
        super(action)
        freeze
      end

      def call(env)
        request  = nil
        response = nil

        halted = catch :halt do
          params   = action.class.params_class.new(env)
          request  = build_request(env, params)
          response = build_response(
            request: request,
            action: action.name,
            configuration: action.configuration,
            content_type: Mime.calculate_content_type_with_charset(action.configuration, request,
                                                                   action.accepted_mime_types),
            env: env,
            headers: action.configuration.default_headers
          )

          action._run_before_callbacks(request, response)
          action.handle(request, response)
          action._run_after_callbacks(request, response)
        rescue StandardError => exception
          action._handle_exception(request, response, exception)
        end

        action.__send__(:finish, request, response, halted)
      end

      private

      alias_method :action, :__getobj__

      def build_request(env, params)
        Request.new(env, params)
      end

      def build_response(**options)
        Response.new(**options)
      end
    end
  end
end
