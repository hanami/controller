module Lotus
  module Action
    class Params < ::Hash
      def initialize(env, request)
        merge! _extract(env, request)
        _symbolize!
        freeze
      end

      private
      def _symbolize!
        keys.each do |k|
          self[k.to_sym] = delete(k)
        end
      end

      if defined?(Lotus::Router)

        def _extract(env, request)
          env.fetch('router.params', env)
        end

      else

        def _extract(env, request)
          if env.has_key?('rack.input')
            request.params
          else
            env
          end
        end

      end # if defined?

    end
  end
end
