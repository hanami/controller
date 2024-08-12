# frozen_string_literal: true

module Hanami
  class Action
    module RequestParams
      # Where ActionValidations provides common interface for handling validations, this Base modules handles the most
      # common and basic methods for accessing params in an action. It is included in both BaseParams and Contract
      # classes since Params inherits from BaseParams and Contract is more independent cause it delegates to
      # Dry::Validation quickly
      #
      # Params is also coupled with Hanami::Validations::Form and this Base module is a way to breach the gap and make
      # them more compatible.
      #
      # since 2.2.0
      # @api private
      module Base
        # @since 0.7.0
        # @api public
        def get(*keys)
          @params.dig(*keys)
        end

        # This is for compatibility with Hanami::Helpers::FormHelper::Values
        #
        # @api private
        # @since 0.8.0
        alias_method :dig, :get

        # Returns a hash of the parsed request params.
        #
        # @return [Hash]
        #
        # @since 0.7.0
        # @api public
        def to_h
          @params
        end
        alias_method :to_hash, :to_h

        # Iterates over the params.
        #
        # Calls the given block with each param key-value pair; returns the full hash of params.
        #
        # @yieldparam key [Symbol]
        # @yieldparam value [Object]
        #
        # @return [to_h]
        #
        # @since 0.7.1
        # @api public
        def each(&blk)
          to_h.each(&blk)
        end

        # Returns the value for the given params key.
        #
        # @param key [Symbol] the key
        #
        # @return [Object,nil] the associated value, if found
        #
        # @since 0.7.0
        # @api public
        def [](key)
          @params[key]
        end
      end
    end
  end
end
