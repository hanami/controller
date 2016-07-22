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

      # This is a Hanami::Validations extension point
      #
      # @since x.x.x
      # @api private
      def self._base_rules
        lambda do
          optional(:_csrf_token).filled(:str?)
        end
      end

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

      # Returns structured error messages
      #
      # @return [Hash]
      #
      # @since x.x.x
      #
      # @example
      #   params.errors
      #     # => {:email=>["is missing", "is in invalid format"], :name=>["is missing"], :tos=>["is missing"], :age=>["is missing"], :address=>["is missing"]}
      def errors
        @result.messages
      end

      # Returns flat collection of full error messages
      #
      # @return [Array]
      #
      # @since x.x.x
      #
      # @example
      #   params.error_messages
      #     # => ["Email is missing", "Email is in invalid format", "Name is missing", "Tos is missing", "Age is missing", "Address is missing"]
      def error_messages(error_set = errors)
        error_set.each_with_object([]) do |(key, messages), result|
          k = Utils::String.new(key).titleize

          _messages = if messages.is_a?(Hash)
            error_messages(messages)
          else
            messages.map { |message| "#{k} #{message}" }
          end

          result.concat(_messages)
        end
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
        # FIXME: this is required for dry-v whitelisting
        stringify!(super)
      end

      def _params
        @result.output.merge(_router_params)
      end

      def stringify!(result)
        result.keys.each do |key|
          value = result.delete(key)
          result[key.to_s] = case value
                             when ::Hash
                               stringify!(value)
                             when ::Array
                               value.map(&:to_s)
                             else
                               value.to_s
                             end
        end

        result
      end
    end
  end
end
