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
      # @since 0.7.0
      # @api private
      def self._base_rules
        lambda do
          optional(:_csrf_token).filled(:str?)
        end
      end

      # Define params validations
      #
      # @param blk [Proc] the validations definitions
      #
      # @since 0.7.0
      #
      # @see http://hanamirb.org/guides/validations/overview/
      #
      # @example
      #   class Signup
      #     MEGABYTE = 1024 ** 2
      #     include Hanami::Action
      #
      #     params do
      #       required(:first_name).filled(:str?)
      #       required(:last_name).filled(:str?)
      #       required(:email).filled?(:str?, format?: /\A.+@.+\z/)
      #       required(:password).filled(:str?).confirmation
      #       required(:terms_of_service).filled(:bool?)
      #       required(:age).filled(:int?, included_in?: 18..99)
      #       optional(:avatar).filled(size?: 1..(MEGABYTE * 3))
      #     end
      #
      #     def call(params)
      #       halt 400 unless params.valid?
      #       # ...
      #     end
      #   end
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
      # @api private
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
      # @since 0.7.0
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
      # @since 0.7.0
      #
      # @example
      #   params.error_messages
      #     # => ["Email is missing", "Email is in invalid format", "Name is missing", "Tos is missing", "Age is missing", "Address is missing"]
      def error_messages(error_set = errors)
        error_set.each_with_object([]) do |(key, messages), result|
          k = Utils::String.titleize(key)

          _messages = if messages.is_a?(Hash)
            error_messages(messages)
          else
            messages.map { |message| "#{k} #{message}" }
          end

          result.concat(_messages)
        end
      end

      # Returns true if no validation errors are found,
      # false otherwise.
      #
      # @return [TrueClass, FalseClass]
      #
      # @since 0.7.0
      #
      # @example
      #   params.valid? # => true
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

      # @api private
      def _params
        _router_params.merge(@result.output)
      end
    end
  end
end
