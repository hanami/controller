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

      # Gets the cookies from the request and expose them as an Hash
      #
      # It automatically sets options from global configuration, but it allows to
      # override values case by case.
      #
      # For a list of options please have a look at <tt>Lotus::Controller::Configuration</tt>,
      # and <tt>Lotus::Action::CookieJar</tt>.
      #
      # @return [Lotus::Action::CookieJar] cookies
      #
      # @since 0.1.0
      # @api public
      #
      # @see Lotus::Controller::Configuration#cookies
      # @see Lotus::Action::CookieJar#[]=
      #
      # @example Basic Usage
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
      #
      # @example Cookies Options
      #   require 'lotus/controller'
      #   require 'lotus/action/cookies'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::Cookies
      #
      #     def call(params)
      #       # ...
      #       # set a value
      #       cookies[:foo] = { value: 'bar', max_age: 300, path: '/dashboard' }
      #     end
      #   end
      def cookies
        @cookies ||= CookieJar.new(@_env.dup, headers, configuration.cookies)
      end

      private

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
    end
  end
end
