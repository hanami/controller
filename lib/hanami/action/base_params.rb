require 'rack/request'
require 'hanami/utils/hash'

module Hanami
  module Action
    class BaseParams
      # The key that returns raw input from the Rack env
      #
      # @since x.x.x
      RACK_INPUT    = 'rack.input'.freeze

      # The key that returns router params from the Rack env
      # This is a builtin integration for Hanami::Router
      #
      # @since x.x.x
      ROUTER_PARAMS = 'router.params'.freeze

      # CSRF params key
      #
      # This key is shared with <tt>hanamirb</tt> and <tt>hanami-helpers</tt>
      #
      # @since x.x.x
      # @api private
      CSRF_TOKEN = '_csrf_token'.freeze

      # Set of params that are never filtered
      #
      # @since x.x.x
      # @api private
      DEFAULT_PARAMS = Hash[CSRF_TOKEN => true].freeze

      # Separator for #get
      #
      # @since x.x.x
      # @api private
      #
      # @see Hanami::Action::Params#get
      GET_SEPARATOR = '.'.freeze

      # @attr_reader env [Hash] the Rack env
      #
      # @since x.x.x
      # @api private
      attr_reader :env

      # @attr_reader raw [Hash] the raw params from the request
      #
      # @since x.x.x
      # @api private
      attr_reader :raw

      # Initialize the params and freeze them.
      #
      # @param env [Hash] a Rack env or an hash of params.
      #
      # @return [Params]
      #
      # @since x.x.x
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
      # @since 0.2.0
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
      # @since x.x.x
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
        result     = self[key.to_sym]

        Array(keys).each do |k|
          break if result.nil?
          result = result[k.to_sym]
        end

        result
      end

      # Serialize params to Hash
      #
      # @return [::Hash]
      #
      # @since x.x.x
      def to_h
        @params
      end
      alias_method :to_hash, :to_h

      private

      # @since x.x.x
      # @api private
      def _extract_params
        result = {}

        if env.key?(RACK_INPUT)
          result.merge! ::Rack::Request.new(env).params
          result.merge! env.fetch(ROUTER_PARAMS, {})
        else
          result.merge! env.fetch(ROUTER_PARAMS, env)
        end

        result
      end
    end
  end
end
