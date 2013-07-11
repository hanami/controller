module Lotus
  module Action
    module Redirect

      protected

      def redirect_to(url, status: 302)
        @_response.redirect(url, status)
      end
    end
  end
end
