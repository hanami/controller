module Lotus
  module Action

    require 'lotus/action/cache/cache_control'

    # Class which stores Expires values
    #
    # @since 0.2.1
    #
    # @api private
    #
    class Expires

      # The HTTP header for Expires
      #
      # @since 0.2.1
      # @api private
      HEADER = 'Expires'.freeze

      def initialize(amount, *values)
        @amount = amount
        @cache_control = Lotus::Action::Cache::CacheControl.new(*(values << { max_age: amount }))
      end

      def headers
        { HEADER => time.httpdate }.merge(@cache_control.headers)
      end

      private

      def time
        Time.now + @amount.to_i
      end
    end
  end
end
