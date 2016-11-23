module Hanami
  module Action
    module Session
      # Wrapper around session hash to provide consistent key access.
      #
      # Since 0.8.0
      class SessionHash < ::SimpleDelegator
        def [](key)
          __getobj__[key.to_s]
        end
        alias :fetch :[]

        def has_key?(key)
          __getobj__.has_key?(key.to_s)
        end
        alias :key? :has_key?
        alias :include? :has_key?

        def []=(key, value)
          __getobj__[key.to_s] = value
        end
        alias :store :[]=

        def delete(key)
          __getobj__.delete(key.to_s)
        end
      end
    end
  end
end
