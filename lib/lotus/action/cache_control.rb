module Lotus
  module Action
    # CacheControl type API
    #
    # @since 0.2.1
    #
    # @see Lotus::Action::CacheControl::ClassMethods#cache_control
    # @see Lotus::Action::CacheControl::ClassMethods#expires
    module CacheControl

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

      # Cache-Control directives which have values
      #
      # @since 0.2.1
      # @api private
      VALUE_DIRECTIVES      = %i(max_age s_maxage).freeze

      # Cache-Control directives which are implicitly true
      #
      # @since 0.2.1
      # @api private
      NON_VALUE_DIRECTIVES  = %i(public private no_cache no_store no_transform must_revalidate proxy_revalidate).freeze

      (NON_VALUE_DIRECTIVES | VALUE_DIRECTIVES).each do |d|
        const_set(d.upcase, d.to_s.tr('_', '-'))
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
        cc_directives = {}

        cache_control_values(*values).each do |segment|
          directive, argument = segment.split('=', 2)
          cc_directives[directive.tr('-', '_').to_sym] = argument || true
        end

        unless cc_directives.empty?
          cc_header = []
          cc_directives.delete(:public) if cc_directives.key? :private
          cc_directives.delete(:private) if cc_directives.key? :public
          cc_directives.each do |k, v|
            if VALUE_DIRECTIVES.include?(k)
              cc_header << "#{CacheControl.const_get(k.upcase)}=#{v.to_i}"
            elsif NON_VALUE_DIRECTIVES.include?(k) && Lotus::Utils::Kernel.Boolean(v)
              cc_header << CacheControl.const_get(k.upcase)
            end
          end
          headers.merge!(CACHE_CONTROL => cc_header.join(', '))
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

      private

      def cache_control_values(*values)
        cache_control_values = []
        values.each do |value|
          if value.is_a? Hash
            cache_control_values.concat(value.map { |k, v|
              argument = v.is_a?(Time) ? v - Time.now : v
              "#{CacheControl.const_get(k.upcase)}=#{argument}"
            })
          elsif value.is_a? Symbol
            cache_control_values << "#{value}=true"
          end
        end
        cache_control_values
      end

    end
  end
end
