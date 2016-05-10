require 'hanami/action/base_params'
require 'hanami/validations/form'

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
    class Params < BaseParams
      include Hanami::Validations::Form

      def self.params(&blk)
        validations(&blk || ->() {})
      end

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

      # Serialize params to Hash
      #
      # @return [::Hash]
      #
      # @since 0.3.0
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
          # FIXME: this is required for dry-v whitelisting
          stringify!(result)
        end

        Utils::Hash.new(result).stringify!.to_h
      end

      def _params
        result = @result.output

        if _csrf_token = raw['_csrf_token']
          result.merge(:_csrf_token => _csrf_token)
        else
          result
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
