module Lotus
  module Action
    # Session API
    #
    # @since 0.1.0
    module Session
      SESSION_KEY = 'rack.session'.freeze

      protected

      # Gets the session from the request
      #
      # @return [Hash] the HTTP session from the request
      #
      # @since 0.1.0
      #
      # @example
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
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
