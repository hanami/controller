# frozen_string_literal: true
require 'byebug'

module Hanami
  class Action
    # A wrapper for defining validation rules using Dry::Validation. This class essentially
    # wraps a Dry::Validation::Contract and acts as a proxy to actually use Dry gem
    #
    # Accessible via the `contract` method in an action class.
    # Although more complex domain-specific validations, or validations concerned with things such as uniqueness
    # are usually better performed at layers deeper than your HTTP actions, Contract still provides helpful features
    # that you can use without contravening the advice form above.
    #
    # @since 2.2.0
    class Contract
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
      end

      # Validates the object, running the Dry::Validation contract and returning it
      # Contract needs to be called explicitly and handled the same way, by itself it does not invalidate the request.
      # @since 2.2.0
      # @api public
      def call
        @result = validate
        result
      end

      attr_reader :result

      private

      # @since 2.2.0
      def validate
        self.class._validator.call(@input)
      end
    end
  end
end
