# frozen_string_literal: true

require "rack/request"
require "hanami/utils/hash"

module Hanami
  class Action
    class BaseParams
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

      # Initializes the params and freezes them.
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
        @params = Utils::Hash.deep_symbolize(@raw)
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

      # Gets an attribute value associated with the given key.
      # Nested attributes are reached by listing all the keys to get to the value.
      #
      # @param keys [Array<Symbol,Integer>] the key
      #
      # @return [Object,NilClass] return the associated value, if found
      #
      # @since 0.7.0
      #
      # @example
      #   require "hanami/controller"
      #
      #   module Deliveries
      #     class Create < Hanami::Action
      #       def handle(req, *)
      #         req.params.get(:customer_name)     # => "Luca"
      #         req.params.get(:uknown)            # => nil
      #
      #         req.params.get(:address, :city)    # => "Rome"
      #         req.params.get(:address, :unknown) # => nil
      #
      #         req.params.get(:tags, 0)           # => "foo"
      #         req.params.get(:tags, 1)           # => "bar"
      #         req.params.get(:tags, 999)         # => nil
      #
      #         req.params.get(nil)                # => nil
      #       end
      #     end
      #   end
      def get(*keys)
        @params.dig(*keys)
      end

      # This is for compatibility with +Hanami::Helpers::FormHelper::Values+
      #
      # @api private
      # @since 0.8.0
      alias_method :dig, :get

      # Provides a common interface with Params
      #
      # @return [TrueClass] always returns true
      #
      # @since 0.7.0
      #
      # @see Hanami::Action::Params#valid?
      def valid?
        true
      end

      # Serializes params to a +Hash+
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

        if env.key?(Action::RACK_INPUT)
          result.merge! ::Rack::Request.new(env).params
          result.merge! _router_params
        else
          result.merge! _router_params(env)
          env[Action::REQUEST_METHOD] ||= Action::DEFAULT_REQUEST_METHOD
        end

        result
      end

      # @since 0.7.0
      # @api private
      def _router_params(fallback = {})
        env.fetch(ROUTER_PARAMS) do
          if session = fallback.delete(Action::RACK_SESSION)
            fallback[Action::RACK_SESSION] = Utils::Hash.deep_symbolize(session)
          end

          fallback
        end
      end
    end
  end
end
