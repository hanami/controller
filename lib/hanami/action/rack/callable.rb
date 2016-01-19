
module Hanami
  module Action
    module Rack
      module Callable
        # Callable module for actions. With this module, actions with middlewares
        # will be able to work with rack builder.
        #
        # @param env [Hash] the full Rack env or the params. This value may vary,
        #   see the examples below.
        #
        # @since 0.4.0
        #
        # @see Hanami::Action::Rack::ClassMethods#rack_builder
        # @see Hanami::Action::Rack::ClassMethods#use
        #
        # @example
        #   require 'hanami/controller'
        #
        #    class MyMiddleware
        #      def initialize(app)
        #        @app = app
        #      end
        #
        #      def call(env)
        #        #...
        #      end
        #    end
        #
        #    class Show
        #      include Hanami::Action
        #      use MyMiddleware
        #
        #      def call(params)
        #        # ...
        #        puts params # => { id: 23 } extracted from Rack env
        #      end
        #    end
        #
        #    Show.respond_to?(:call) # => true
        def call(env)
          rack_builder.call(env)
        end
      end
    end
  end
end
