module Hanami
  module Action
    module Cache
      # @since 0.3.0
      # @api private
      IF_NONE_MATCH = 'HTTP_IF_NONE_MATCH'.freeze

      # The HTTP header for ETag
      #
      # @since 0.3.0
      # @api private
      ETAG          = 'ETag'.freeze

      # @since 0.3.0
      # @api private
      IF_MODIFIED_SINCE = 'HTTP_IF_MODIFIED_SINCE'.freeze

      # The HTTP header for Last-Modified
      #
      # @since 0.3.0
      # @api private
      LAST_MODIFIED = 'Last-Modified'.freeze

      # ETag value object
      #
      # @since 0.3.0
      # @api private
      #
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

      # LastModified value object
      #
      # @since 0.3.0
      # @api private
      class LastModified
        def initialize(env, value)
          @env, @value = env, value
        end

        def fresh?
          !Hanami::Utils::Blank.blank?(modified_since) && Time.httpdate(modified_since).to_i >= @value.to_i
        end

        def header
          { LAST_MODIFIED => @value.httpdate } if modified_since
        end

        private

        def modified_since
          @env[IF_MODIFIED_SINCE]
        end
      end

      # Class responsible to determine if a given request is fresh
      # based on IF_NONE_MATCH and IF_MODIFIED_SINCE headers
      #
      # @since 0.3.0
      # @api private
      class ConditionalGet
        def initialize(env, options)
          @validations = [ ETag.new(env, options[:etag]), LastModified.new(env, options[:last_modified]) ]
        end

        def fresh?
          yield if @validations.any?(&:fresh?)
        end

        def headers
          @validations.map(&:header).compact.reduce Hash.new, :merge
        end
      end
    end
  end
end
