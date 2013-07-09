module Lotus
  module Utils
    class Hash < ::Hash
      def initialize(hash = {})
        merge! hash
      end

      def symbolize!
        keys.each do |k|
          v = delete(k)
          v = Hash.new(v).symbolize! if v.is_a?(::Hash)

          self[k.to_sym] = v
        end

        self
      end
    end
  end
end
