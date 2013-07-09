require 'lotus/utils/hash'

module Lotus
  module Action
    class Params < Utils::Hash
      def initialize(env)
        super _extract(env)
        symbolize!
        freeze
      end

      private
      def _extract(env)
        {}.tap do |result|
          if env.has_key?('rack.input')
            result.merge! ::Rack::Request.new(env).params
            result.merge! env.fetch('router.params', {})
          else
            result.merge! env.fetch('router.params', env)
          end
        end
      end
    end
  end
end
