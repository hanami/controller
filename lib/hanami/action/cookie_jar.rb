require 'hanami/utils/hash'

module Hanami
  module Action
    # A set of HTTP Cookies
    #
    # It acts as an Hash
    #
    # @since 0.1.0
    #
    # @see Hanami::Action::Cookies#cookies
    class CookieJar
      # The key that returns raw cookies from the Rack env
      #
      # @since 0.1.0
      # @api private
      HTTP_HEADER       = 'HTTP_COOKIE'.freeze

      # The key used by Rack to set the session cookie
      #
      # We let CookieJar to NOT take care of this cookie, but it leaves the
      # responsibility to the Rack middleware that handle sessions.
      #
      # This prevents <tt>Set-Cookie</tt> to be sent twice.
      #
      # @since 0.5.1
      # @api private
      #
      # @see https://github.com/hanami/controller/issues/138
      RACK_SESSION_KEY   = :'rack.session'

      # The key used by Rack to set the cookies as an Hash in the env
      #
      # @since 0.1.0
      # @api private
      COOKIE_HASH_KEY   = 'rack.request.cookie_hash'.freeze

      # The key used by Rack to set the cookies as a String in the env
      #
      # @since 0.1.0
      # @api private
      COOKIE_STRING_KEY = 'rack.request.cookie_string'.freeze

      # @since 0.4.5
      # @api private
      COOKIE_SEPARATOR = ';,'.freeze

      # Initialize the CookieJar
      #
      # @param env [Hash] a raw Rack env
      # @param headers [Hash] the response headers
      #
      # @return [CookieJar]
      #
      # @since 0.1.0
      def initialize(env, headers, default_options)
        @_headers        = headers
        @cookies         = Utils::Hash.new(extract(env)).deep_symbolize!
        @default_options = default_options
      end

      # Finalize itself, by setting the proper headers to add and remove
      # cookies, before the response is returned to the webserver.
      #
      # @return [void]
      #
      # @since 0.1.0
      #
      # @see Hanami::Action::Cookies#finish
      def finish
        @cookies.delete(RACK_SESSION_KEY)
        @cookies.each do |k,v|
          next unless changed?(k)
          v.nil? ? delete_cookie(k) : set_cookie(k, _merge_default_values(v))
        end if changed?
      end

      # Returns the object associated with the given key
      #
      # @param key [Symbol] the key
      #
      # @return [Object,nil] return the associated object, if found
      #
      # @since 0.2.0
      def [](key)
        @cookies[key]
      end

      # Associate the given value with the given key and store them
      #
      # @param key [Symbol] the key
      # @param value [#to_s,Hash] value that can be serialized as a string or
      #   expressed as a Hash
      # @option value [String] :value - Value of the cookie
      # @option value [String] :domain - The domain
      # @option value [String] :path - The path
      # @option value [Integer] :max_age - Duration expressed in seconds
      # @option value [Time] :expires - Expiration time
      # @option value [TrueClass,FalseClass] :secure - Restrict cookie to secure
      #   connections
      # @option value [TrueClass,FalseClass] :httponly - Restrict JavaScript
      #   access
      #
      # @return [void]
      #
      # @since 0.2.0
      #
      # @see http://en.wikipedia.org/wiki/HTTP_cookie
      def []=(key, value)
        changes << key
        @cookies[key] = value
      end

      private

      # Keep track of changed keys
      #
      # @since 0.7.0
      # @api private
      def changes
        @changes ||= Set.new
      end

      # Check if the entire set of cookies has changed within the current request.
      # If <tt>key</tt> is given, it checks the associated cookie has changed.
      #
      # @since 0.7.0
      # @api private
      def changed?(key = nil)
        if key.nil?
          changes.any?
        else
          changes.include?(key)
        end
      end

      # Merge default cookies options with values provided by user
      #
      # Cookies values provided by user are respected
      #
      # @since 0.4.0
      # @api private
      def _merge_default_values(value)
        cookies_options = if value.is_a? Hash
          value.merge! _add_expires_option(value)
        else
          { value: value }
        end
        @default_options.merge cookies_options
      end

      # Add expires option to cookies if :max_age presents
      #
      # @since 0.4.3
      # @api private
      def _add_expires_option(value)
        if value.has_key?(:max_age) && !value.has_key?(:expires)
          { expires: (Time.now + value[:max_age]) }
        else
          {}
        end
      end

      # Extract the cookies from the raw Rack env.
      #
      # This implementation is borrowed from Rack::Request#cookies.
      #
      # @since 0.1.0
      # @api private
      def extract(env)
        hash   = env[COOKIE_HASH_KEY] ||= {}
        string = env[HTTP_HEADER]

        return hash if string == env[COOKIE_STRING_KEY]
        # TODO Next Rack 1.7.x ?? version will have ::Rack::Utils.parse_cookies
        # We can then replace the following lines.
        hash.clear

        # According to RFC 2109:
        #   If multiple cookies satisfy the criteria above, they are ordered in
        #   the Cookie header such that those with more specific Path attributes
        #   precede those with less specific.  Ordering with respect to other
        #   attributes (e.g., Domain) is unspecified.
        cookies = ::Rack::Utils.parse_query(string, COOKIE_SEPARATOR) { |s| ::Rack::Utils.unescape(s) rescue s }
        cookies.each { |k,v| hash[k] = Array === v ? v.first : v }
        env[COOKIE_STRING_KEY] = string
        hash
      end

      # Set a cookie in the headers
      #
      # @since 0.1.0
      # @api private
      def set_cookie(key, value)
        ::Rack::Utils.set_cookie_header!(@_headers, key, value)
      end

      # Remove a cookie from the headers
      #
      # @since 0.1.0
      # @api private
      def delete_cookie(key)
        ::Rack::Utils.delete_cookie_header!(@_headers, key, {})
      end
    end
  end
end
