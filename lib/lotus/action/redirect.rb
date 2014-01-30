module Lotus
  module Action
    # HTTP redirect API
    #
    # @since 0.1.0
    module Redirect

      protected

      # Redirect to the given URL
      #
      # @param url [String] the destination URL
      # @param status [Fixnum] the http code
      #
      # @since 0.1.0
      #
      # @example
      #   require 'lotus/controller'
      #
      #   class Create
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       redirect_to 'http://example.com/articles/23'
      #     end
      #   end
      def redirect_to(url, status: 302)
        @_response.redirect(url, status)
      end
    end
  end
end
