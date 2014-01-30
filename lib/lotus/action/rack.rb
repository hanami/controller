module Lotus
  module Action
    # Rack integration API
    #
    # @since 0.1.0
    module Rack
      protected

      # Sets the HTTP status code for the response
      #
      # @param status [Fixnum] an HTTP status code
      # @return [void]
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
      #       self.status = 201
      #     end
      #   end
      def status=(status)
        @_response.status = status
      end

      # Sets the body of the response
      #
      # @param body [String] the body of the response
      # @return [void]
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
      #       self.body = 'Hi!'
      #     end
      #   end
      def body=(body)
        @_response.body = [ body ]
      end

      # Gets the headers from the response
      #
      # @return [Hash] the HTTP headers from the response
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
      #       self.headers            # => { ... }
      #       self.headers.merge!({'X-Custom' => 'OK'})
      #     end
      #   end
      def headers
        @_response.headers
      end

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
        @_request.session
      end
    end
  end
end
