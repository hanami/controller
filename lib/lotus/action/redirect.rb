module Lotus
  module Action
    # HTTP redirect API
    #
    # @since 0.1.0
    module Redirect
      # The HTTP header for redirects
      #
      # @since 0.2.0
      # @api private
      LOCATION = 'Location'.freeze

      private

      # Redirect to the given URL
      #
      # @param url [String] the destination URL
      # @param status [Fixnum] the http code
      #
      # @since 0.1.0
      #
      # @example With default status code (302)
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
      #
      #   action = Create.new
      #   action.call({}) # => [302, {'Location' => '/articles/23'}, '']
      #
      # @example With custom status code
      #   require 'lotus/controller'
      #
      #   class Create
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       redirect_to 'http://example.com/articles/23', status: 301
      #     end
      #   end
      #
      #   action = Create.new
      #   action.call({}) # => [301, {'Location' => '/articles/23'}, '']
      def redirect_to(url, status: 302)
        headers[LOCATION] = url
        self.status = status
      end
    end
  end
end
