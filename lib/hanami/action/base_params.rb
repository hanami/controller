require 'rack/request'
require 'hanami/utils/hash'

module Hanami
  module Action
    class BaseParams
      # The key that returns raw input from the Rack env
      #
      # @since 0.7.0
      RACK_INPUT    = 'rack.input'.freeze

      # The key that returns router params from the Rack env
      # This is a builtin integration for Hanami::Router
      #
      # @since 0.7.0
      ROUTER_PARAMS = 'router.params'.freeze

      # Separator for #get
      #
      # @since 0.7.0
      # @api private
      #
      # @see Hanami::Action::Params#get
      GET_SEPARATOR = '.'.freeze

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
      def initialize(env)
        @env    = env
        @raw    = _extract_params
        @params = Utils::Hash.new(@raw).symbolize!.to_h
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
      # Nested attributes are reached with a dot notation.
      #
      # @param key [String] the key
      #
      # @return [Object,NilClass] return the associated value, if found
      #
      # @raise [NoMethodError] if key is nil
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
      #         params.get('customer_name')   # => "Luca"
      #         params.get('uknown')          # => nil
      #
      #         params.get('address.city')    # => "Rome"
      #         params.get('address.unknown') # => nil
      #
      #         params.get(nil)               # => nil
      #       end
      #     end
      #   end
      def get(key)
        key, *keys = key.to_s.split(GET_SEPARATOR)
        return if key.nil?

        result = self[key.to_sym]

        Array(keys).each do |k|
          break if result.nil?
          result = result[k.to_sym]
        end

        result
      end

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
      # @since x.x.x
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
        env.fetch(ROUTER_PARAMS, fallback)
      end
    end
  end
end
