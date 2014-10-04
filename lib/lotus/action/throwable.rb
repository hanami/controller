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
      # @since 0.2.0
      # @api private
      RACK_ERRORS = 'rack.errors'.freeze

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        private

        # Handle the given exception with an HTTP status code.
        #
        # When the exception is raise during #call execution, it will be
        # translated into the associated HTTP status.
        #
        # This is a fine grained control, for a global configuration see
        # Lotus::Action.handled_exceptions
        #
        # @param exception [Hash] the exception class must be the key and the
        #   HTTP status the value of the hash
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
      # @since 0.2.0
      #
      # @see Lotus::Controller#handled_exceptions
      # @see Lotus::Action::Throwable#handle_exception
      # @see Lotus::Http::Status:ALL
      def halt(code = nil)
        status(*Http::Status.for_code(code)) if code
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

      private
      # @since 0.1.0
      # @api private
      def _rescue
        catch :halt do
          begin
            yield
          rescue => exception
            _reference_in_rack_errors(exception)
            _handle_exception(exception)
          end
        end
      end

      # @since 0.2.0
      # @api private
      def _reference_in_rack_errors(exception)
        if errors = @_env[RACK_ERRORS]
          errors.write(_dump_exception(exception))
          errors.flush
        end
      end

      # @since 0.2.0
      # @api private
      def _dump_exception(exception)
        [[exception.class, exception.message].compact.join(": "), *exception.backtrace].join("\n\t")
      end

      # @since 0.1.0
      # @api private
      def _handle_exception(exception)
        raise unless configuration.handle_exceptions
        handler = configuration.exception_handler(exception.class)

        if handler.is_a?(Symbol)
          method(handler).call(exception)
          halt
        else
          halt handler
        end
      end
    end
  end
end
