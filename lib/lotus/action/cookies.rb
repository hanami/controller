require 'lotus/action/cookie_jar'

module Lotus
  module Action
    module Cookies

      protected

      def finish
        super
        cookies.finish
      end

      def cookies
        @cookies ||= CookieJar.new(@_request, @_response)
      end
    end
  end
end
