require 'hanami/action/cache/cache_control'
require 'hanami/action/cache/expires'
require 'hanami/action/cache/conditional_get'

module Hanami
  class Action
    # Cache type API
    #
    # @since 0.3.0
    #
    # @see Hanami::Action::Cache::ClassMethods#cache_control
    # @see Hanami::Action::Cache::ClassMethods#expires
    # @see Hanami::Action::Cache::ClassMethods#fresh
    module Cache
      # Override Ruby's hook for modules.
      # It includes exposures logic
      #
      # @param base [Class] the target action
      #
      # @since 0.3.0
      # @api private
      #
      # @see http://www.ruby-doc.org/core/Module.html#method-i-included
      def self.included(base)
        base.class_eval do
          include CacheControl, Expires
        end
      end

      protected

      # Set the etag, last_modified, or both headers on the response
      # and halts a 304 Not Modified if the request is still fresh
      # respecting IfNoneMatch and IfModifiedSince request headers
      #
      # @param options [Hash]
      # @option options [Integer] :etag for testing IfNoneMatch conditions
      # @option options [Date] :last_modified for testing IfModifiedSince conditions
      #
      # @return void
      #
      # @since 0.3.0
      #
      # @example
      #   require 'hanami/controller'
      #   require 'hanami/action/cache'
      #
      #   class Show
      #     include Hanami::Action
      #     include Hanami::Action::Cache
      #
      #     def call(params)
      #       # ...
      #
      #       # set etag response header and halt 304
      #       # if request matches IF_NONE_MATCH header
      #       fresh etag: @resource.updated_at.to_i
      #
      #       # set last_modified response header and halt 304
      #       # if request matches IF_MODIFIED_SINCE
      #       fresh last_modified: @resource.updated_at
      #
      #       # set etag and last_modified response header,
      #       # halt 304 if request matches IF_MODIFIED_SINCE
      #       # and IF_NONE_MATCH
      #       fresh last_modified: @resource.updated_at
      #
      #     end
      #   end
      def fresh(options)
        conditional_get = ConditionalGet.new(request.env, options)

        response.headers.merge!(conditional_get.headers)

        conditional_get.fresh? do
          halt 304
        end
      end
    end
  end
end
