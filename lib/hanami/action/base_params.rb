require 'rack/request'
require 'hanami/utils/hash'

module Hanami
  module Action
    class BaseParams
      # The key that returns raw input from the Rack env
      #
      # @since 0.7.0
      # @api private
      RACK_INPUT    = 'rack.input'.freeze

      # The key that returns router params from the Rack env
      # This is a builtin integration for Hanami::Router
      #
      # @since 0.7.0
      # @api private
      ROUTER_PARAMS = 'router.params'.freeze

      # The key that returns Rack session params from the Rack env
      # Please note that this is used only when an action is unit tested.
      #
      # @since 1.0.0.beta1
      # @api private
      #
      # @example
      #   # action unit test
      #   action.call('rack.session' => { 'foo' => 'bar' })
      #   action.session[:foo] # => "bar"
      RACK_SESSION = 'rack.session'.freeze

      # @attr_reader env [Hash] the Rack env
      #
      # @since 0.7.0
      # @api private
      attr_reader :env

      # @attr_reader raw [Hash] the raw params from the request
      #
      # @since 0.7.0
      # @api private
      attr_reader :raw

      # Initialize the params and freeze them.
      #
      # @param env [Hash] a Rack env or an hash of params.
      #
      # @return [Params]
      #
      # @since 0.7.0
      # @api private
      def initialize(env)
        @env    = env
        @raw    = _extract_params
        @params = Utils::Hash.new(@raw).deep_dup.deep_symbolize!.to_h
        freeze
      end

      # Returns the object associated with the given key
      #
      # @param key [Symbol] the key
      #
      # @return [Object,nil] return the associated object, if found
      #
      # @since 0.7.0
      def [](key)
        @params[key]
      end

      # Get an attribute value associated with the given key.
      # Nested attributes are reached by listing all the keys to get to the value.
      #
      # @param keys [Array<Symbol,Integer>] the key
      #
      # @return [Object,NilClass] return the associated value, if found
      #
      # @since 0.7.0
      #
      # @example
      #   require 'hanami/controller'
      #
      #   module Deliveries
      #     class Create
      #       include Hanami::Action
      #
      #       def call(params)
      #         params.get(:customer_name)     # => "Luca"
      #         params.get(:uknown)            # => nil
      #
      #         params.get(:address, :city)    # => "Rome"
      #         params.get(:address, :unknown) # => nil
      #
      #         params.get(:tags, 0)           # => "foo"
      #         params.get(:tags, 1)           # => "bar"
      #         params.get(:tags, 999)         # => nil
      #
      #         params.get(nil)                # => nil
      #       end
      #     end
      #   end
      def get(*keys)
        @params.dig(*keys)
      end

      # This is for compatibility with Hanami::Helpers::FormHelper::Values
      #
      # @api private
      # @since 0.8.0
      alias dig get

      # Provide a common interface with Params
      #
      # @return [TrueClass] always returns true
      #
      # @since 0.7.0
      #
      # @see Hanami::Action::Params#valid?
      def valid?
        true
      end

      # Serialize params to Hash
      #
      # @return [::Hash]
      #
      # @since 0.7.0
      def to_h
        @params
      end
      alias_method :to_hash, :to_h

      # Iterates through params
      #
      # @param blk [Proc]
      #
      # @since 0.7.1
      def each(&blk)
        to_h.each(&blk)
      end

      private

      # @since 0.7.0
      # @api private
      def _extract_params
        result = {}

        if env.key?(RACK_INPUT)
          result.merge! ::Rack::Request.new(env).params
          result.merge! _router_params
        else
          result.merge! _router_params(env)
        end

        result
      end

      # @since 0.7.0
      # @api private
      def _router_params(fallback = {})
        env.fetch(ROUTER_PARAMS) do
          if session = fallback.delete(RACK_SESSION) # rubocop:disable Lint/AssignmentInCondition
            fallback[RACK_SESSION] = Utils::Hash.new(session).symbolize!.to_hash
          end

          fallback
        end
      end
    end
  end
end
