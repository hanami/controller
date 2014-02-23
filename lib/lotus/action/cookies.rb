require 'lotus/action/cookie_jar'

module Lotus
  module Action
    # Cookies API
    #
    # This module isn't included by default.
    #
    # @since 0.1.0
    #
    # @see Lotus::Action::Cookies#cookies
    module Cookies

      protected

      # Finalize the response by flushing cookies into the response
      #
      # @since 0.1.0
      # @api private
      #
      # @see Lotus::Action#finish
      def finish
        super
        cookies.finish
      end

      # Gets the cookies from the request and expose them as an Hash
      #
      # @return [Lotus::Action::CookieJar] the cookies
      #
      # @since 0.1.0
      # @api public
      #
      # @example
      #   require 'lotus/controller'
      #   require 'lotus/action/cookies'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::Cookies
      #
      #     def call(params)
      #       # ...
      #
      #       # get a value
      #       cookies[:user_id] # => '23'
      #
      #       # set a value
      #       cookies[:foo] = 'bar'
      #
      #       # remove a value
      #       cookies[:bax] = nil
      #     end
      #   end
      def cookies
        @cookies ||= CookieJar.new(@_env.dup, headers)
      end
    end
  end
end
