require 'lotus/utils/hash'

module Lotus
  module Action
    class CookieJar < Utils::Hash
      def initialize(request, response)
        @_response = response

        super(request.cookies)
        symbolize!
      end

      def finish
        each do |k,v|
          if v.nil?
            @_response.delete_cookie(k)
          else
            @_response.set_cookie(k, v)
          end
        end
      end
    end
  end
end
