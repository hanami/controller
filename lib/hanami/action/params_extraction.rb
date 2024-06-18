# frozen_string_literal: true

require "rack/request"

module Hanami
  class Action
    class ParamsExtraction
      def initialize(env)
        @env = env
      end

      def call
        _extract_params
      end

      private

      attr_reader :env

      def _extract_params
        result = {}

        if env.key?(Action::RACK_INPUT)
          result.merge! ::Rack::Request.new(env).params
          result.merge! _router_params
        else
          result.merge! _router_params(env)
          env[Action::REQUEST_METHOD] ||= Action::DEFAULT_REQUEST_METHOD
        end

        result
      end

      def _router_params(fallback = {})
        env.fetch(ROUTER_PARAMS) do
          if (session = fallback.delete(Action::RACK_SESSION))
            fallback[Action::RACK_SESSION] = Utils::Hash.deep_symbolize(session)
          end

          fallback
        end
      end
    end
  end
end
