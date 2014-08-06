module Lotus
  module Action

    # The HTTP header for Cache-Control
    #
    # @since 0.2.1
    # @api private
    CACHE_CONTROL = 'Cache-Control'.freeze

    # Class which stores CacheControl values
    #
    # @since 0.2.1
    #
    # @api private
    #
    require 'lotus/action/cache/directives'

    class CacheControl
      def initialize(*values)
        @directives = Lotus::Action::Cache::Directives.new(*values)
      end

      def headers
        if @directives.any?
          { CACHE_CONTROL => @directives.join(', ') }
        else
          {}
        end
      end
    end
  end
end
