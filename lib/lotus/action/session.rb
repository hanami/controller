module Lotus
  module Action
    # Session API
    #
    # This module isn't included by default.
    #
    # @since 0.1.0
    module Session
      # The key that returns raw session from the Rack env
      #
      # @since 0.1.0
      # @api private
      SESSION_KEY = 'rack.session'.freeze

      private

      # Gets the session from the request and expose it as an Hash.
      #
      # @return [Hash] the HTTP session from the request
      #
      # @since 0.1.0
      #
      # @example
      #   require 'lotus/controller'
      #   require 'lotus/action/session'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::Session
      #
      #     def call(params)
      #       # ...
      #
      #       # get a value
      #       session[:user_id] # => '23'
      #
      #       # set a value
      #       session[:foo] = 'bar'
      #
      #       # remove a value
      #       session[:bax] = nil
      #     end
      #   end
      def session
        @_env[SESSION_KEY] ||= {}
      end
    end
  end
end
