require 'lotus/utils/hash'

module Lotus
  module Action
    class Params < Utils::Hash
      RACK_INPUT    = 'rack.input'.freeze
      ROUTER_PARAMS = 'router.params'.freeze

      def initialize(env)
        super _extract(env)
        symbolize!
        freeze
      end

      private
      def _extract(env)
        {}.tap do |result|
          if env.has_key?(RACK_INPUT)
            result.merge! ::Rack::Request.new(env).params
            result.merge! env.fetch(ROUTER_PARAMS, {})
          else
            result.merge! env.fetch(ROUTER_PARAMS, env)
          end
        end
      end
    end
  end
end
