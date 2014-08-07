require 'lotus/action/cache/cache_control'
require 'lotus/action/cache/expires'
require 'lotus/action/cache/conditional_get'

module Lotus
  module Action
    # Cache type API
    #
    # @since x.x.x
    #
    # @see Lotus::Action::Cache::ClassMethods#cache_control
    # @see Lotus::Action::Cache::ClassMethods#expires
    # @see Lotus::Action::Cache::ClassMethods#fresh
    module Cache
      # Override Ruby's hook for modules.
      # It includes exposures logic
      #
      # @param base [Class] the target action
      #
      # @since x.x.x
      # @api private
      #
      # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
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
      # @since x.x.x
      # @api public
      #
      # @example
      #   require 'lotus/controller'
      #   require 'lotus/action/cache'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::Cache
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
      #
      def cache_control(*values)
        cache_control = CacheControl::Directives.new(*values)
        headers.merge!(cache_control.headers)
      end

      # Set the Expires header and Cache-Control/max-age directive. Amount
      # can be an integer number of seconds in the future or a Time object
      # indicating when the response should be considered "stale". The remaining
      # "values" arguments are passed to the #cache_control helper:
      #
      # @since x.x.x
      # @api public
      #
      # @example
      #   require 'lotus/controller'
      #   require 'lotus/action/cache'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::Cache
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
      #
      def expires(amount, *values)
        expires = Expires::Directives.new(amount, *values)
        headers.merge!(expires.headers)
      end

      # Set the etag, last_modified, or both headers on the response
      # and halts a 304 Not Modified if the request is still fresh
      # respecting IfNoneMatch and IfModifiedSince request headers
      #
      # @since x.x.x
      # @api public
      #
      # @example
      #   require 'lotus/controller'
      #   require 'lotus/action/cache'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::Cache
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
