module Lotus
  module Action
    class CookieJar < ::Hash
      def initialize(request, response)
        merge! request.cookies
        _symbolize!
        @_response = response
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

      private
      def _symbolize!
        keys.each do |k|
          self[k.to_sym] = delete(k)
        end
      end
    end
  end
end
