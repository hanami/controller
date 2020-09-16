# frozen_string_literal: true

module Hanami
  class Action
    # A container to transport data with the HTTP session, with a lifespan of
    # just one HTTP request or redirect.
    #
    # Behaves like a hash, returning entries for the current request, except for
    # {#[]=}, which updates the hash for the next request.
    #
    # @since 0.3.0
    # @api public
    class Flash
      # @return [Hash] The flash hash for the next request, written to by {#[]=}.
      #
      # @see #[]=
      #
      # @since 2.0.0
      # @api public
      attr_reader :next

      # Initializes a new flash instance
      #
      # @param hash [Hash, nil] the flash hash for the current request. nil will become an empty hash.
      #
      # @since 0.3.0
      # @api public
      def initialize(hash = {})
        @flash = hash || {}
        @next = {}
      end

      # @return [Hash] The flash hash for the current request
      #
      # @since 2.0.0
      # @api public
      def now
        @flash
      end

      # @since 2.0.0
      # @api public
      alias to_h now

      # Returns a value associated with the given key
      #
      # @param key [Object] the key
      #
      # @return value [Object,NilClass] the value
      #
      # @since 0.3.0
      # @api public
      def [](key)
        @flash[key]
      end

      # Updates the next hash with the given key and value
      #
      # @param key [Object] the key
      # @param value [Object] the value
      #
      # @since 0.3.0
      # @api public
      def []=(key, value)
        @next[key] = value
      end

      # Iterates through current request data and kept data
      #
      # @param blk [Proc]
      #
      # @since 1.2.0
      # @api public
      def each(&blk)
        @flash.each(&blk)
      end

      # Iterates through current request data and kept data
      #
      # @param blk [Proc]
      # @return [Array]
      #
      # @since 1.2.0
      # @api public
      def map(&blk)
        @flash.map(&blk)
      end

      # Check if flash is empty.
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.3.0
      # @api public
      def empty?
        @flash.empty?
      end

      # Check if there is a value associated with the given key.
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 2.0.0
      # @api public
      def key?(key)
        @flash.key?(key)
      end

      # Removes entries from the next hash
      #
      # @overload discard(key)
      #   Removes the given key from the next hash
      #
      #   @param key [Object] key to discard
      #
      # @overload discard
      #   Clears the next hash
      #
      # @since 2.0.0
      # @api public
      def discard(key = (no_arg = true))
        if no_arg
          @next.clear
        else
          @next.delete(key)
        end
      end

      # Copies entries from the current hash to the next hash
      #
      # @overload keep(key)
      #   Copies the entry for the given key from the current hash to the next
      #   hash
      #
      #   @param key [Object] key to copy
      #
      # @overload keep
      #   Copies all entries from the current hash to the next hash
      #
      # @since 2.0.0
      # @api public
      def keep(key = (no_arg = true))
        if no_arg
          @next.merge!(@flash)
        else
          self[key] = self[key]
        end
      end

      # Replaces the current hash with the next hash and clears the next hash
      #
      # @since 2.0.0
      # @api public
      def sweep
        @flash = @next.dup
        @next.clear
        self
      end
    end
  end
end
