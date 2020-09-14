require 'hanami/utils/json'

module Hanami
  class Action
    class Flash < DelegateClass(Hash)
      # The flash hash for the next request.  This
      # is what gets written to by #[]=.
      attr_reader :next

      # The flash hash for the current request
      alias now __getobj__

      # Setup the next hash when initializing, and handle treat nil
      # as a new empty hash.
      def initialize(hash = {})
        super(hash||{})
        @next = {}
      end

      # Update the next hash with the given key and value.
      def []=(k, v)
        @next[k] = v
      end

      # Remove given key from the next hash, or clear the next hash if
      # no argument is given.
      def discard(key=(no_arg=true))
        if no_arg
          @next.clear
        else
          @next.delete(key)
        end
      end

      # Copy the entry with the given key from the current hash to the
      # next hash, or copy all entries from the current hash to the
      # next hash if no argument is given.
      def keep(key=(no_arg=true))
        if no_arg
          @next.merge!(self)
        else
          self[key] = self[key]
        end
      end

      # Replace the current hash with the next hash and clear the next hash.
      def sweep
        replace(@next)
        @next.clear
        self
      end
    end
  end
end
