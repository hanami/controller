require 'lotus/utils/hash'
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
        @env    = env
        @params = _compute_params
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

      # Whitelists the named parameter
      #
      # Whitelist the named parameter.  Whitelisted parameters
      # will be stored while unwhitelisted parater values will
      # be ignored.
      #
      # @example
      #
      #   class SignupParams < Lotus::Action::Params
      #     param :email
      #   end
      #
      #   params = SignupParams.new({id: 23, email: 'mjb@example.com'})
      #   params[:email] # => 'mjb@example.com'
      #   params[:id]]   # => nil
      #
      # @return [nil] return nil
      #
      # @since 0.2.0
      def self.param(name)
        _names << name
        nil
      end

      def self._names
        @names ||= Set.new
      end
      private_class_method :_names

      # Returns whether or not params are being whitelisted
      #
      # @return [true, false] return whether whitelisting is being used
      #
      # @since 0.2.0
      def self.whitelisting?
        _names.any?
      end

      # Returns whether the named param has been whitelisted
      #
      # @param name [Symbol] the key
      #
      # @return [true, false] return whether the named param is whitelisted
      #
      # @since 0.2.0
      def self.whitelisted?(name)
        _names.include?(name)
      end

      private
      def _compute_params
        params = Utils::Hash.new(_extract).symbolize!
        params = _whitelist(params)
      end

      def _extract
        {}.tap do |result|
          if env.has_key?(RACK_INPUT)
            result.merge! ::Rack::Request.new(env).params
            result.merge! env.fetch(ROUTER_PARAMS, {})
          else
            result.merge! env.fetch(ROUTER_PARAMS, env)
          end
        end
      end

      def _whitelist(raw_params)
        if self.class.whitelisting?
          raw_params.select do |k, v|
            self.class.whitelisted?(k)
          end
        else
          raw_params
        end
      end

    end
  end
end
