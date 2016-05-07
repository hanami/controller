require 'hanami/validations/form'
require 'hanami/utils/hash'
require 'hanami/utils/class_attribute'

module Hanami
  module Action
    # A set of params requested by the client
    #
    # It's able to extract the relevant params from a Rack env of from an Hash.
    #
    # There are three scenarios:
    #   * When used with Hanami::Router: it contains only the params from the request
    #   * When used standalone: it contains all the Rack env
    #   * Default: it returns the given hash as it is. It's useful for testing purposes.
    #
    # @since 0.1.0
    class Params
      # The key that returns raw input from the Rack env
      #
      # @since 0.1.0
      RACK_INPUT    = 'rack.input'.freeze

      # The key that returns router params from the Rack env
      # This is a builtin integration for Hanami::Router
      #
      # @since 0.1.0
      ROUTER_PARAMS = 'router.params'.freeze

      # CSRF params key
      #
      # This key is shared with <tt>hanamirb</tt> and <tt>hanami-helpers</tt>
      #
      # @since 0.4.4
      # @api private
      CSRF_TOKEN = '_csrf_token'.freeze

      # Set of params that are never filtered
      #
      # @since 0.4.4
      # @api private
      DEFAULT_PARAMS = Hash[CSRF_TOKEN => true].freeze

      # Separator for #get
      #
      # @since 0.4.0
      # @api private
      #
      # @see Hanami::Action::Params#get
      GET_SEPARATOR = '.'.freeze

      include Hanami::Validations::Form

      def self.inherited(klass)
        klass.class_eval do
          include Hanami::Utils::ClassAttribute

          class_attribute :_validations
          self._validations = false
        end
      end

      def self.params(&blk)
        if blk.nil?
          validations {}
        else
          validations(&blk)
          self._validations = true
        end
      end

      # @attr_reader env [Hash] the Rack env
      #
      # @since 0.2.0
      # @api private
      attr_reader :env

      # Initialize the params and freeze them.
      #
      # @param env [Hash] a Rack env or an hash of params.
      #
      # @return [Params]
      #
      # @since 0.1.0
      def initialize(env)
        @env = env
        super(_extract_params)
        @result = validate
        @params = _params
        freeze
      end

      # Returns raw params from Rack env
      #
      # @return [Hash]
      #
      # @since 0.3.2
      def raw
        @input
      end

      def errors
        @result.messages
      end

      def valid?
        @result.success?
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
      # @since 0.4.0
      #
      # @example
      #   require 'hanami/controller'
      #
      #   module Deliveries
      #     class Create
      #       include Hanami::Action
      #
      #       params do
      #         param :customer_name
      #         param :address do
      #           param :city
      #         end
      #       end
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
      # @since 0.3.0
      def to_h
        @params
      end
      alias_method :to_hash, :to_h

      # Assign CSRF Token.
      # This method is here for compatibility with <tt>Hanami::Validations</tt>.
      #
      # NOTE: When we will not support indifferent access anymore, we can probably
      # remove this method.
      #
      # @since 0.4.4
      # @api private
      def _csrf_token=(value)
        @params.set(CSRF_TOKEN, value)
      end

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
          # FIXME: this is required for dry-v whitelisting
          stringify!(result)
        end

        Utils::Hash.new(result).stringify!.to_h
      end

      def _params
        if self.class._validations
          result = @result.output

          if _csrf_token = raw['_csrf_token']
            result.merge(:_csrf_token => _csrf_token)
          else
            result
          end
        else
          Utils::Hash.new(raw).symbolize!.to_h
        end
      end

      def stringify!(result)
        result.keys.each do |key|
          value = result.delete(key)
          result[key.to_s] = value.to_s
        end

        result
      end
    end
  end
end
