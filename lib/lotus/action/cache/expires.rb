module Lotus
  module Action

    # The HTTP header for Expires
    #
    # @since 0.2.1
    # @api private
    EXPIRES = 'Expires'.freeze

    # Class which stores Expires values
    #
    # @since 0.2.1
    #
    # @api private
    #
    require 'lotus/action/cache/cache_control'

    class Expires
      def initialize(amount, *values)
        @amount = amount
        @cache_control = Lotus::Action::Cache::CacheControl.new(*(values << { max_age: amount }))
      end

      def headers
        { EXPIRES => time.httpdate }.merge(@cache_control.headers)
      end

      private

      def time
        Time.now + @amount.to_i
      end
    end
  end
end
