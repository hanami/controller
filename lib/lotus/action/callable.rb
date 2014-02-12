require 'lotus/action/params'

module Lotus
  module Action
    module Callable
      def call(env)
        _rescue do
          @_env    = env
          @headers = ::Rack::Utils::HeaderHash.new
          super        Params.new(@_env)
        end

        finish
      end

      protected

      def finish
        super
        response
      end
    end
  end
end
