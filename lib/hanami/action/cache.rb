# frozen_string_literal: true

require "hanami/action/cache/cache_control"
require "hanami/action/cache/expires"
require "hanami/action/cache/conditional_get"

module Hanami
  module Action
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

      # Specify response freshness policy for HTTP caches (Cache-Control header).
      # Any number of non-value directives (:public, :private, :no_cache,
      # :no_store, :must_revalidate, :proxy_revalidate) may be passed along with
      # a Hash of value directives (:max_age, :min_stale, :s_max_age).
      #
      # See RFC 2616 / 14.9 for more on standard cache control directives:
      # http://tools.ietf.org/html/rfc2616#section-14.9.1
      #
      # @param values [Array<Symbols, Hash>] mapped to cache_control directives
      # @option values [Symbol] :public
      # @option values [Symbol] :private
      # @option values [Symbol] :no_cache
      # @option values [Symbol] :no_store
      # @option values [Symbol] :must_validate
      # @option values [Symbol] :proxy_revalidate
      # @option values [Hash] :max_age
      # @option values [Hash] :min_stale
      # @option values [Hash] :s_max_age
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
      #       # set Cache-Control directives
      #       cache_control :public, max_age: 900, s_maxage: 86400
      #
      #       # overwrite previous Cache-Control directives
      #       cache_control :private, :no_cache, :no_store
      #
      #       => Cache-Control: private, no-store, max-age=900
      #
      #     end
      #   end
      def cache_control(*values)
        cache_control = CacheControl::Directives.new(*values)
        headers.merge!(cache_control.headers)
      end

      # Set the Expires header and Cache-Control/max-age directive. Amount
      # can be an integer number of seconds in the future or a Time object
      # indicating when the response should be considered "stale". The remaining
      # "values" arguments are passed to the #cache_control helper:
      #
      # @param amount [Integer,Time] number of seconds or point in time
      # @param values [Array<Symbols>] mapped to cache_control directives
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
      #       # set Cache-Control directives and Expires
      #       expires 900, :public
      #
      #       # overwrite Cache-Control directives and Expires
      #       expires 300, :private, :no_cache, :no_store
      #
      #       => Expires: Thu, 26 Jun 2014 12:00:00 GMT
      #       => Cache-Control: private, no-cache, no-store max-age=300
      #
      #     end
      #   end
      def expires(amount, *values)
        expires = Expires::Directives.new(amount, *values)
        headers.merge!(expires.headers)
      end

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
        conditional_get = ConditionalGet.new(@_env, options)

        headers.merge!(conditional_get.headers)

        conditional_get.fresh? do
          halt 304
        end
      end
    end
  end
end
