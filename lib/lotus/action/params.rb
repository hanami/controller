module Lotus
  module Action
    class Params < ::Hash
      def initialize(env)
        merge! _extract(env)
        _symbolize!
        freeze
      end

      private
      def _symbolize!
        keys.each do |k|
          self[k.to_sym] = delete(k)
        end
      end

      if defined?(::Lotus::Router)

        def _extract(env)
          env.fetch('router.params', env)
        end

      else

        def _extract(env)
          if env.has_key?('rack.input')
            ::Rack::Request.new(env).params
          else
            env
          end
        end

      end # if defined?

    end
  end
end
