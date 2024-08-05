# frozen_string_literal: true

module Hanami
  class Action
    # A wrapper for defining validation rules using Dry::Validation. This class essentially
    # wraps a Dry::Validation::Contract and acts as a proxy to actually use Dry gem
    #
    # Defined via the `contract` block in an action class.
    # Although more complex domain-specific validations, or validations concerned with things such as uniqueness
    # are usually better performed at layers deeper than your HTTP actions, Contract still provides helpful features
    # that you can use without contravening the advice form above.
    #
    # @since 2.2.0
    class Contract
      # A wrapper for the result of a contract validation
      # @since 2.2.0
      # @api private
      class Result < SimpleDelegator
        # @since 2.0.0
        # @api private
        def to_h
          __getobj__.to_h
        end

        # @since 2.0.0
        # @api private
        def errors
          __getobj__.errors.to_h
        end
      end

      # @attr_reader env [Hash] the Rack env
      #
      # @since 2.2.0
      # @api private
      attr_reader :env

      # Define a contract for the given action
      #
      # @param blk [Proc] the block to define the contract, including [Params] as a contract schema and connected rules
      #
      # @since 2.2.0
      # @api private
      #
      # @example
      # class Create < Hanami::Action
      #   contract do
      #     params do
      #       required(:birth_date).value(:date)
      #     end
      #     rule(:birth_date) do
      #       key.failure('you must be 18 years or older to register') if value > Date.today - 18.years
      #     end
      #   end
      #
      #   def handle(req, *)
      #     halt 400 unless req.contract.call.errors.empty?
      #     # ...
      #   end
      # end
      def self.contract(&blk)
        @_validator = Dry::Validation::Contract.build(&blk)
      end

      # @since 2.2.0
      # @api private
      class << self
        attr_reader :_validator
      end

      # Initialize the contract and freeze it.
      #
      # @param env [Hash] a Rack env or an hash of params.
      #
      # @return [Hash]
      #
      # @since 2.2.0
      # @api public
      def initialize(env)
        @env = env
        @input = Hanami::Action::ParamsExtraction.new(env).call
        validation = validate
        @params = validation.to_h
        @errors = Hanami::Action::Params::Errors.new(validation.errors)
        freeze
      end

      attr_reader :errors

      # Returns true if no validation errors are found,
      # false otherwise.
      #
      # @return [TrueClass, FalseClass]
      #
      # @since 2.2.0
      #
      def valid?
        errors.empty?
      end

      # Serialize validated params to Hash
      #
      # @return [::Hash]
      #
      # @since 2.2.0
      def to_h
        validate.to_h
      end

      attr_reader :result

      # Returns the value for the given params key.
      #
      # @param key [Symbol] the key
      #
      # @return [Object,nil] the associated value, if found
      #
      # @since 2.2.0
      # @api public
      def [](key)
        @params[key]
      end

      private

      # @since 2.2.0
      def validate
        Result.new(
          self.class._validator.call(@input)
        )
      end
    end
  end
end
