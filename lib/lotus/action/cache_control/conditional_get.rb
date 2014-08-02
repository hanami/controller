module Lotus
  module Action
    module CacheControl
      # @since 0.2.1
      # @api private
      IF_NONE_MATCH = 'IF_NONE_MATCH'.freeze

      # The HTTP header for ETag
      #
      # @since 0.2.1
      # @api private
      ETAG          = 'ETag'.freeze

      class ConditionalGet
        def initialize(env, options)
          @env, @etag = env, options[:etag]
        end

        def fresh?
          yield if @etag == @env[IF_NONE_MATCH]
        end

        def headers
          { ETAG => @etag }
        end
      end
    end
  end
end
