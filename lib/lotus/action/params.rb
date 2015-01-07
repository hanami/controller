require 'lotus/utils/attributes'
require 'lotus/validations'
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
      def self.param(name, options = {})
        attribute name, options
        nil
      end

      include Lotus::Validations

      def self.whitelisting?
        defined_attributes.any?
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

      # Returns the Ruby's hash
      #
      # @return [Hash]
      #
      # @since 0.3.0
      def to_h
        @attributes.to_h
      end
      alias_method :to_hash, :to_h

      private
      # Compatibility with Lotus::Validations
      #
      # @since 0.3.1
      # @api private
      def read_attributes
        to_h
      end

      # @since 0.3.1
      # @api private
      def _compute_params
        @attributes = if self.class.whitelisting?
          _whitelisted_params
        else
          _params
        end

        @attributes = Utils::Attributes.new(@attributes)
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
          _params.each do |k, v|
            next unless self.class.defined_attributes.include?(k.to_s)

            result[k] = v
          end
        end
      end
    end
  end
end
