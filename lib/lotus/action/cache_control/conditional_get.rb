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

      # @since 0.2.1
      # @api private
      IF_MODIFIED_SINCE = 'IF_MODIFIED_SINCE'.freeze

      # The HTTP header for Last-Modified
      #
      # @since 0.2.1
      # @api private
      LAST_MODIFIED = 'Last-Modified'.freeze

      class ETag
        def initialize(env, value)
          @env, @value = env, value
        end

        def fresh?
          @env[IF_NONE_MATCH] && @value == @env[IF_NONE_MATCH]
        end

        def header
          { ETAG => @value } if fresh?
        end
      end

      class LastModified
        def initialize(env, value)
          @env, @value = env, value
        end

        def fresh?
          @env[IF_MODIFIED_SINCE] && @value.to_i >= Time.httpdate(@env[IF_MODIFIED_SINCE]).to_i
        end

        def header
          { LAST_MODIFIED => @value } if fresh?
        end
      end

      class ConditionalGet
        def initialize(env, options)
          @validations = [ ETag.new(env, options[:etag]), LastModified.new(env, options[:last_modified]) ]
        end

        def fresh?
          yield if @validations.any? &:fresh?
        end

        def headers
          @validations.map &:header
        end
      end
    end
  end
end
