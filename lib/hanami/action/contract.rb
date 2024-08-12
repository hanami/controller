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
      include Hanami::Action::RequestParams::ActionValidations
      include Hanami::Action::RequestParams::Base
      # A wrapper for the result of a contract validation
      # @since 2.2.0
      # @api private
      class Result < SimpleDelegator
        # @since 2.0.0
        # @api private
        def to_h
          __getobj__.to_h
        end

        # This method is called messages not errors to be consistent with the Hanami::Validations::Result
        #
        # @return [Hash] the error messages
        #
        # @since 2.0.0
        # @api private
        def messages
          __getobj__.errors.to_h
        end
      end

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
