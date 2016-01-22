require 'hanami/action/params'

module Hanami
  module Action
    module Callable
      # Execute application logic.
      # It implements the Rack protocol.
      #
      # The request params are passed as an argument to the `#call` method.
      #
      # If routed with Hanami::Router, it extracts the relevant bits from the
      # Rack `env` (eg the requested `:id`).
      #
      # Otherwise everything it's passed as it is: the full Rack `env`
      # in production, and the given `Hash` for unit tests. See the examples
      # below.
      #
      # Application developers are forced to implement this method in their
      # actions.
      #
      # @param env [Hash] the full Rack env or the params. This value may vary,
      #   see the examples below.
      #
      # @return [Array] a serialized Rack response (eg. `[200, {}, ["Hi!"]]`)
      #
      # @since 0.1.0
      #
      # @example with Hanami::Router
      #   require 'hanami/controller'
      #
      #    class Show
      #      include Hanami::Action
      #
      #      def call(params)
      #        # ...
      #        puts params # => { id: 23 } extracted from Rack env
      #      end
      #    end
      #
      # @example Standalone
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #
      #     def call(params)
      #       # ...
      #       puts params
      #         # => { :"rack.version"=>[1, 2],
      #         #      :"rack.input"=>#<StringIO:0x007fa563463948>, ... }
      #     end
      #   end
      #
      # @example Unit Testing
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #
      #     def call(params)
      #       # ...
      #       puts params # => { id: 23, key: 'value' } passed as it is from testing
      #     end
      #   end
      #
      #   action   = Show.new
      #   response = action.call({ id: 23, key: 'value' })
      def call(env)
        _rescue do
          @_env    = env
          @headers = ::Rack::Utils::HeaderHash.new(configuration.default_headers)
          @params  = self.class.params_class.new(@_env)
          super @params
        end

        finish
      end

      private

      # Prepare the Rack response before the control is returned to the
      # webserver.
      #
      # @since 0.1.0
      # @api private
      #
      # @see Hanami::Action#finish
      def finish
        super
        response
      end
    end
  end
end
