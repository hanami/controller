require 'lotus/action/session'
module Lotus
  module Action
    # Flash API
    #
    # @since 0.1.0
    #
    # @see Lotus::Action::Flash
    module Flash
      def self.included(action)
        action.class_eval do
          include Lotus::Action::Session
          prepend InstanceMethods
        end
      end

      class FlashHash
        attr_reader :flagged

        def initialize(store)
          @cache = {}
          @store = store
        end

        # Remove an entry from the session and return its value. Cache result in
        # the instance cache.
        #
        # @return The value for the key.
        #
        # @example in a template:
        # <%= flash[:notice] %>
        #
        # When flash[:notice] is read, its value will be cleared out.
        def [](key)
          key = key.to_sym
          cache[key] ||= store.delete(key)
        end

        # Store the entry in the session, updating the instance cache as well.
        #
        # @return The value for the key.
        #
        # @example
        # require 'lotus/controller'
        #
        # class Show
        #   include Lotus::Action::Flash
        #
        #   def call(params)
        #     flash[:notice] = "Thanks for signing up!"
        #   end
        # end
        def []=(key,val)
          key = key.to_sym
          cache[key] = store[key] = val
        end

        # Checks for the presence of a flash entry without retrieving or removing
        # it from the cache or store.
        # @return true or false, depending if the flash has the key.
        #
        # @example
        # flash.has?(:notice)
        def has?(key)
          [cache, store].any? { |store| store.keys.include?(key.to_sym) }
        end
        alias_method :include?, :has?

        # Checks for the presence of a flash entry without retrieving or removing
        # it from the cache or store.
        # @return the keys currently in the flash
        #
        # @example
        # flash.keys
        def keys
          cache.keys | store.keys
        end

        # @return the flash cache in its current state.
        #
        # @example
        # flash.now
        def now
          cache
        end

        private

        attr_reader :cache, :store
      end

      module InstanceMethods
        protected

        def flash
          return @flash if @flash

          session['__flash__'] ||= {}
          @flash = FlashHash.new(session['__flash__'])
        end
      end
    end
  end
end
