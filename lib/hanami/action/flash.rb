# frozen_string_literal: true

module Hanami
  class Action
    # A container to transport data with the HTTP session, with a lifespan of
    # just one HTTP request or redirect.
    #
    # Behaves like a hash, returning entries for the current request, except for
    # {#[]=}, which updates the hash for the next request.
    #
    # This implementation is derived from Roda's FlashHash, also released under
    # the MIT Licence:
    #
    # Copyright (c) 2014-2020 Jeremy Evans
    # Copyright (c) 2010-2014 Michel Martens, Damian Janowski and Cyril David
    # Copyright (c) 2008-2009 Christian Neukirchen
    #
    # @since 0.3.0
    # @api public
    class Flash
      # @since 2.0.0
      # @api private
      KEY = "_flash"

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

      # Returns the value for the given key in the current hash
      #
      # @param key [Object] the key
      #
      # @return [Object, nil] the value
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

      # Calls the given block once for each element in the current hash
      #
      # @param block [Proc]
      #
      # @since 1.2.0
      # @api public
      def each(&block)
        @flash.each(&block)
      end

      # Returns a new array with the results of running block once for every
      # element in the current hash
      #
      # @param block [Proc]
      # @return [Array]
      #
      # @since 1.2.0
      # @api public
      def map(&block)
        @flash.map(&block)
      end

      # Returns `true` if the current hash contains no elements.
      #
      # @return [Boolean]
      #
      # @since 0.3.0
      # @api public
      def empty?
        @flash.empty?
      end

      # Returns `true` if the given key is present in the current hash.
      #
      # @return [Boolean]
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
        raise FrozenError if frozen?

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
        raise FrozenError if frozen?

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
        raise FrozenError if frozen?

        @flash = @next.dup
        @next.clear
        self
      end

      # Freeze the flash object
      #
      # @since 2.0.0
      # @api public
      def freeze
        # TODO: deep freeze hashes
        @flash.freeze
        @next.freeze

        super
      end
    end
  end
end
