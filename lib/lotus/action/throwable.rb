require 'lotus/utils/class_attribute'
require 'lotus/http/status'

module Lotus
  module Action
    # Throw API
    #
    # @since 0.1.0
    #
    # @see Lotus::Action::Throwable::ClassMethods#handle_exception
    # @see Lotus::Action::Throwable#halt
    # @see Lotus::Action::Throwable#status
    module Throwable
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
        protected

        # Handle the given exception with an HTTP status code.
        #
        # When the exception is raise during #call execution, it will be
        # translated into the associated HTTP status.
        #
        # This is a fine grained control, for a global configuration see
        # Lotus::Action.handled_exceptions
        #
        # @param exception [Class] the exception class
        # @param status [Fixmun] a valid HTTP status
        #
        # @since 0.1.0
        #
        # @see Lotus::Action.handled_exceptions
        #
        # @example
        #   require 'lotus/controller'
        #
        #   class Show
        #     include Lotus::Action
        #     handle_exception RecordNotFound => 404
        #
        #     def call(params)
        #       # ...
        #       raise RecordNotFound.new
        #     end
        #   end
        #
        #   Show.new.call({id: 1}) # => [404, {}, ['Not Found']]
        def handle_exception(exception)
          configuration.handle_exception(exception)
        end
      end

      protected

      # Halt the action execution with the given HTTP status code.
      #
      # When used, the execution of a callback or of an action is interrupted
      # and the control returns to the framework, that decides how to handle
      # the event.
      #
      # It also sets the response body with the message associated to the code
      # (eg 404 will set `"Not Found"`).
      #
      # @param code [Fixnum] a valid HTTP status code
      #
      # @since 0.1.1
      #
      # @see Lotus::Controller#handled_exceptions
      # @see Lotus::Action::Throwable#handle_exception
      # @see Lotus::Http::Status:ALL
      def halt(code)
        status(*Http::Status.for_code(code))
        throw :halt
      end

      # Sets the given code and message for the response
      #
      # @param code [Fixnum] a valid HTTP status code
      # @param message [String] the response body
      #
      # @since 0.1.0
      # @see Lotus::Http::Status:ALL
      def status(code, message)
        self.status = code
        self.body   = message
      end

      def throw(*args)
        if Fixnum === args.first
          warn "Passing a status code to `throw` is deprecated and will be removed from Lotus::Controller. Use `halt` method instead."
          halt(args.first)
        end

        super
      end

      private
      def _rescue
        catch :halt do
          begin
            yield
          rescue => exception
            _handle_exception(exception)
          end
        end
      end

      def _handle_exception(exception)
        raise unless configuration.handle_exceptions
        halt configuration.exception_code(exception.class)
      end
    end
  end
end
