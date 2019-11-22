require 'hanami/utils/class_attribute'
require 'hanami/http/status'
require 'hanami/action/rack/error_processing'

module Hanami
  module Action
    # Throw API
    #
    # @since 0.1.0
    #
    # @see Hanami::Action::Throwable::ClassMethods#handle_exception
    # @see Hanami::Action::Throwable#halt
    # @see Hanami::Action::Throwable#status
    module Throwable
      # @since 0.1.0
      # @api private
      def self.included(base)
        base.extend ClassMethods
      end

      # Throw API class methods
      #
      # @since 0.1.0
      # @api private
      module ClassMethods
        private

        # Handle the given exception with an HTTP status code.
        #
        # When the exception is raise during #call execution, it will be
        # translated into the associated HTTP status.
        #
        # This is a fine grained control, for a global configuration see
        # Hanami::Action.handled_exceptions
        #
        # @param exception [Hash] the exception class must be the key and the
        #   HTTP status the value of the hash
        #
        # @since 0.1.0
        #
        # @see Hanami::Action.handled_exceptions
        #
        # @example
        #   require 'hanami/controller'
        #
        #   class Show
        #     include Hanami::Action
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

      # Halt the action execution with the given HTTP status code and message.
      #
      # When used, the execution of a callback or of an action is interrupted
      # and the control returns to the framework, that decides how to handle
      # the event.
      #
      # If a message is provided, it sets the response body with the message.
      # Otherwise, it sets the response body with the default message associated
      # to the code (eg 404 will set `"Not Found"`).
      #
      # @param code [Fixnum] a valid HTTP status code
      # @param message [String] the response body
      #
      # @since 0.2.0
      #
      # @see Hanami::Controller#handled_exceptions
      # @see Hanami::Action::Throwable#handle_exception
      # @see Hanami::Http::Status:ALL
      #
      # @example Basic usage
      #   require 'hanami/controller'
      #
      #   class Show
      #     def call(params)
      #       halt 404
      #     end
      #   end
      #
      #   # => [404, {}, ["Not Found"]]
      #
      # @example Custom message
      #   require 'hanami/controller'
      #
      #   class Show
      #     def call(params)
      #       halt 404, "This is not the droid you're looking for."
      #     end
      #   end
      #
      #   # => [404, {}, ["This is not the droid you're looking for."]]
      def halt(code, message = nil)
        message ||= Http::Status.message_for(code)
        status(code, message)

        throw :halt
      end

      # Sets the given code and message for the response
      #
      # @param code [Fixnum] a valid HTTP status code
      # @param message [String] the response body
      #
      # @since 0.1.0
      # @see Hanami::Http::Status:ALL
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
        return if configuration.handled_exception?(exception)

        Hanami::Action::Rack::ErrorProcessing.save_error_in_rack_env(@_env, exception)
      end

      # @since 0.1.0
      # @api private
      def _handle_exception(exception)
        raise unless configuration.handle_exceptions

        instance_exec(
          exception,
          &_exception_handler(exception)
        )
      end

      # @since 0.3.0
      # @api private
      def _exception_handler(exception)
        handler = configuration.exception_handler(exception)

        if respond_to?(handler.to_s, true)
          method(handler)
        else
          ->(ex) { halt handler }
        end
      end
    end
  end
end
