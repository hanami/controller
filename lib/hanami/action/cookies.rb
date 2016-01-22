require 'hanami/action/cookie_jar'

module Hanami
  module Action
    # Cookies API
    #
    # This module isn't included by default.
    #
    # @since 0.1.0
    #
    # @see Hanami::Action::Cookies#cookies
    module Cookies
      protected

      # Gets the cookies from the request and expose them as an Hash
      #
      # It automatically sets options from global configuration, but it allows to
      # override values case by case.
      #
      # For a list of options please have a look at <tt>Hanami::Controller::Configuration</tt>,
      # and <tt>Hanami::Action::CookieJar</tt>.
      #
      # @return [Hanami::Action::CookieJar] cookies
      #
      # @since 0.1.0
      # @api public
      #
      # @see Hanami::Controller::Configuration#cookies
      # @see Hanami::Action::CookieJar#[]=
      #
      # @example Basic Usage
      #   require 'hanami/controller'
      #   require 'hanami/action/cookies'
      #
      #   class Show
      #     include Hanami::Action
      #     include Hanami::Action::Cookies
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
      #   require 'hanami/controller'
      #   require 'hanami/action/cookies'
      #
      #   class Show
      #     include Hanami::Action
      #     include Hanami::Action::Cookies
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
      # @see Hanami::Action#finish
      def finish
        super
        cookies.finish
      end
    end
  end
end
