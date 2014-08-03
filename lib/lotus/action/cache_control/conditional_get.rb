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
          none_match && @value == none_match
        end

        def header
          { ETAG => @value } if none_match
        end

        private

        def none_match
          @env[IF_NONE_MATCH]
        end
      end

      class LastModified
        def initialize(env, value)
          @env, @value = env, value
        end

        def fresh?
          modified_since && Time.httpdate(modified_since).to_i >= @value.to_i
        end

        def header
          { LAST_MODIFIED => @value.httpdate } if modified_since
        end

        private

        def modified_since
          @env[IF_MODIFIED_SINCE]
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
          @validations.map(&:header).compact.reduce Hash.new, :merge
        end
      end
    end
  end
end
