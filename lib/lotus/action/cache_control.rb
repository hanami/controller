module Lotus
  module Action
    # CacheControl type API
    #
    # @since 0.2.1
    #
    # @see Lotus::Action::CacheControl::ClassMethods#cache_control
    # @see Lotus::Action::CacheControl::ClassMethods#expires
    module CacheControl

      require 'lotus/action/cache_control/directives'

      # The HTTP header for Cache-Control
      #
      # @since 0.2.1
      # @api private
      CACHE_CONTROL         = 'Cache-Control'.freeze

      # The HTTP header for Expires
      #
      # @since 0.2.1
      # @api private
      EXPIRES               = 'Expires'.freeze

      # The HTTP header for ETag
      #
      # @since 0.2.1
      # @api private
      ETAG                  = 'ETag'.freeze

      protected

      # Specify response freshness policy for HTTP caches (Cache-Control header).
      # Any number of non-value directives (:public, :private, :no_cache,
      # :no_store, :must_revalidate, :proxy_revalidate) may be passed along with
      # a Hash of value directives (:max_age, :min_stale, :s_max_age).
      #
      # See RFC 2616 / 14.9 for more on standard cache control directives:
      # http://tools.ietf.org/html/rfc2616#section-14.9.1
      #
      # @since 0.2.1
      # @api public
      #
      # @example
      #   require 'lotus/controller'
      #   require 'lotus/action/cache_control'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::CacheControl
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
        directives = Directives.new(*values)

        if directives.any?
          headers.merge!(CACHE_CONTROL => directives.join(', '))
        end
      end

      # Set the Expires header and Cache-Control/max-age directive. Amount
      # can be an integer number of seconds in the future or a Time object
      # indicating when the response should be considered "stale". The remaining
      # "values" arguments are passed to the #cache_control helper:
      #
      # @since 0.2.1
      # @api public
      #
      # @example
      #   require 'lotus/controller'
      #   require 'lotus/action/cache_control'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::CacheControl
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
        if amount.is_a? Integer
          time    = Time.now + amount.to_i
          max_age = amount
        else
          time    = amount
          max_age = time - Time.now
        end

        directives = *values
        directives << { max_age: max_age }

        headers.merge!(EXPIRES => time.httpdate)

        cache_control(*directives)
      end

      # Set the etag, last_modified, or both headers on the response
      # and halts a 304 Not Modified if the request is still fresh
      # respecting IfNoneMatch and IfModifiedSince request headers
      #
      # @since 0.2.1
      # @api public
      #
      # @example
      #   require 'lotus/controller'
      #   require 'lotus/action/cache_control'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::CacheControl
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
        headers.merge!(ETAG => options[:etag])

        if current_etag = @_env['IF_NONE_MATCH']
          halt 304 if current_etag == options[:etag]
        end
      end
    end
  end
end
