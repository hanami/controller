module Lotus
  module Action
    module Cache

      require 'lotus/action/cache/directives'

      # Class which stores CacheControl values
      #
      # @since 0.2.1
      #
      # @api private
      #
      class CacheControl

        # The HTTP header for Cache-Control
        #
        # @since 0.2.1
        # @api private
        HEADER = 'Cache-Control'.freeze

        def initialize(*values)
          @directives = Lotus::Action::Cache::Directives.new(*values)
        end

        def headers
          if @directives.any?
            { HEADER => @directives.join(', ') }
          else
            {}
          end
        end
      end
    end
  end
end
