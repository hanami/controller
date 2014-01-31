require 'lotus/utils/hash'

module Lotus
  module Action
    class CookieJar < Utils::Hash
      HTTP_HEADER       = 'HTTP_COOKIE'.freeze
      COOKIE_HASH_KEY   = 'rack.request.cookie_hash'.freeze
      COOKIE_STRING_KEY = 'rack.request.cookie_string'.freeze

      def initialize(env, headers)
        @_headers = headers

        super(extract(env))
        symbolize!
      end

      def finish
        each {|k,v| v.nil? ? delete_cookie(k) : set_cookie(k, v) }
      end

      private
      def extract(env)
        hash   = env[COOKIE_HASH_KEY] ||= {}
        string = env[HTTP_HEADER]

        return hash if string == env[COOKIE_STRING_KEY]
        hash.clear

        # According to RFC 2109:
        #   If multiple cookies satisfy the criteria above, they are ordered in
        #   the Cookie header such that those with more specific Path attributes
        #   precede those with less specific.  Ordering with respect to other
        #   attributes (e.g., Domain) is unspecified.
        cookies = ::Rack::Utils.parse_query(string, ';,') { |s| ::Rack::Utils.unescape(s) rescue s }
        cookies.each { |k,v| hash[k] = Array === v ? v.first : v }
        env[COOKIE_STRING_KEY] = string
        hash
      end

      def set_cookie(key, value)
        ::Rack::Utils.set_cookie_header!(@_headers, key, value)
      end

      def delete_cookie(key)
        ::Rack::Utils.delete_cookie_header!(@_headers, key, {})
      end
    end
  end
end
