require 'lotus/validations'
require 'lotus/utils/attributes'
require 'set'

module Lotus
  module Action
    # A set of params requested by the client
    #
    # It's able to extract the relevant params from a Rack env of from an Hash.
    #
    # There are three scenarios:
    #   * When used with Lotus::Router: it contains only the params from the request
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
      # This is a builtin integration for Lotus::Router
      #
      # @since 0.1.0
      ROUTER_PARAMS = 'router.params'.freeze

      # CSRF params key
      #
      # This key is shared with <tt>lotusrb</tt> and <tt>lotus-helpers</tt>
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
      # @see Lotus::Action::Params#get
      GET_SEPARATOR = '.'.freeze

      # Whitelist and validate a parameter
      #
      # @param name [#to_sym] The name of the param to whitelist
      #
      # @raise [ArgumentError] if one the validations is unknown, or if
      #   the size validator is used with an object that can't be coerced to
      #   integer.
      #
      # @return void
      #
      # @since 0.3.0
      #
      # @see http://rdoc.info/gems/lotus-validations/Lotus/Validations
      #
      # @example Whitelisting
      #   require 'lotus/controller'
      #
      #   class SignupParams < Lotus::Action::Params
      #     param :email
      #   end
      #
      #   params = SignupParams.new({id: 23, email: 'mjb@example.com'})
      #
      #   params[:email] # => 'mjb@example.com'
      #   params[:id]    # => nil
      #
      # @example Validation
      #   require 'lotus/controller'
      #
      #   class SignupParams < Lotus::Action::Params
      #     param :email, presence: true
      #   end
      #
      #   params = SignupParams.new({})
      #
      #   params[:email] # => nil
      #   params.valid?  # => false
      #
      # @example Unknown validation
      #   require 'lotus/controller'
      #
      #   class SignupParams < Lotus::Action::Params
      #     param :email, unknown: true # => raise ArgumentError
      #   end
      #
      # @example Wrong size validation
      #   require 'lotus/controller'
      #
      #   class SignupParams < Lotus::Action::Params
      #     param :email, size: 'twentythree'
      #   end
      #
      #   params = SignupParams.new({})
      #   params.valid? # => raise ArgumentError
      def self.param(name, options = {}, &block)
        attribute name, options, &block
        nil
      end

      include Lotus::Validations

      def self.whitelisting?
        defined_attributes.any?
      end

      # Overrides the method in Lotus::Validation to build a class that
      # inherits from Params rather than only Lotus::Validations.
      #
      # @since 0.3.2
      # @api private
      def self.build_validation_class(&block)
        kls = Class.new(Params) do
          def lotus_nested_attributes?
            true
          end
        end
        kls.class_eval(&block)
        kls
      end

      # @attr_reader env [Hash] the Rack env
      #
      # @since 0.2.0
      # @api private
      attr_reader :env

      # @attr_reader raw [Lotus::Utils::Attributes] all request's attributes
      #
      # @since 0.3.2
      attr_reader :raw

      # Initialize the params and freeze them.
      #
      # @param env [Hash] a Rack env or an hash of params.
      #
      # @return [Params]
      #
      # @since 0.1.0
      def initialize(env)
        @env = env
        super(_compute_params)
        # freeze
      end

      # Returns the object associated with the given key
      #
      # @param key [Symbol] the key
      #
      # @return [Object,nil] return the associated object, if found
      #
      # @since 0.2.0
      def [](key)
        @attributes.get(key)
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
      #   require 'lotus/controller'
      #
      #   module Deliveries
      #     class Create
      #       include Lotus::Action
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
        result     = self[key]

        Array(keys).each do |k|
          break if result.nil?
          result = result[k]
        end

        result
      end

      # Serialize params to Hash
      #
      # @return [::Hash]
      #
      # @since 0.3.0
      def to_h
        @attributes.to_h
      end
      alias_method :to_hash, :to_h

      # Assign CSRF Token.
      # This method is here for compatibility with <tt>Lotus::Validations</tt>.
      #
      # NOTE: When we will not support indifferent access anymore, we can probably
      # remove this method.
      #
      # @since 0.4.4
      # @api private
      def _csrf_token=(value)
        @attributes.set(CSRF_TOKEN, value)
      end

      private
      # @since 0.3.1
      # @api private
      def _compute_params
        if self.class.whitelisting?
          _whitelisted_params
        else
          @attributes = _raw
        end
      end

      # @since 0.3.2
      # @api private
      def _raw
        @raw ||= Utils::Attributes.new(_params)
      end

      # @since 0.3.1
      # @api private
      def _params
        {}.tap do |result|
          if env.has_key?(RACK_INPUT)
            result.merge! ::Rack::Request.new(env).params
            result.merge! env.fetch(ROUTER_PARAMS, {})
          else
            result.merge! env.fetch(ROUTER_PARAMS, env)
          end
        end
      end

      # @since 0.3.1
      # @api private
      def _whitelisted_params
        {}.tap do |result|
          _raw.to_h.each do |k, v|
            next unless assign_attribute?(k)

            result[k] = v
          end
        end
      end

      # Override <tt>Lotus::Validations</tt> method
      #
      # @since 0.4.4
      # @api private
      def assign_attribute?(key)
        DEFAULT_PARAMS[key.to_s] || super
      end
    end
  end
end
