# frozen_string_literal: true

module Hanami
  class Action
    # A wrapper for Params class that allows for defining validation rules using Dry::Validation
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
      #  contract do
      #    params do
      #      required(:birth_date).value(:date)
      #    end
      #    rule(:birth_date) do
      #      key.failure('you must be 18 years or older to register') if value > Date.today - 18.years
      #    end
      #
      #    def handle(req, *)
      #      halt 400 unless req.contract.errors
      #      # ...
      #    end
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
      # @return [nie wiem jeszcze]
      #
      # @since 2.2.0
      # @api public
      def initialize(env)
        @env = env
        @input = extract_params
      end

      # Validates the object, running the Dry::Validation contract and returning it
      # @since 2.2.0
      # @api public
      def call
        @result = validate
        result
      end

      attr_reader :result

      private

      # TODO: shared with params.rb
      def validate
        self.class._validator.call(@input)
      end

      def extract_params
        result = {}

        if env.key?(Action::RACK_INPUT)
          result.merge! ::Rack::Request.new(env).params
          result.merge! _router_params
        else
          result.merge! _router_params(env)
          env[Action::REQUEST_METHOD] ||= Action::DEFAULT_REQUEST_METHOD
        end

        result
      end

      def _router_params(fallback = {})
        env.fetch(ROUTER_PARAMS) do
          if session = fallback.delete(Action::RACK_SESSION)
            fallback[Action::RACK_SESSION] = Utils::Hash.deep_symbolize(session)
          end

          fallback
        end
      end
    end
  end
end
