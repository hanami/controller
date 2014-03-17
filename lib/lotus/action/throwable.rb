require 'lotus/utils/class_attribute'
require 'lotus/http/status'

module Lotus
  module Action
    # Throw API
    #
    # @since 0.1.0
    #
    # @see Lotus::Action::Throwable::ClassMethods#handle_exception
    # @see Lotus::Action::Throwable#throw
    # @see Lotus::Action::Throwable#status
    module Throwable
      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
        def self.extended(base)
          base.class_eval do
            include Utils::ClassAttribute

            # Action handled exceptions.
            #
            # When a handled exception is raised during #call execution, it will be
            # translated into the associated HTTP status.
            #
            # By default there aren't handled exceptions, all the errors are treated
            # as a Server Side Error (500).
            #
            # @api private
            # @since 0.1.0
            #
            # @see Lotus::Controller.handled_exceptions
            # @see Lotus::Action::Throwable.handle_exception
            class_attribute :handled_exceptions
            self.handled_exceptions = Controller.handled_exceptions.dup
          end
        end

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
        #     handle_exception RecordNotFound, 404
        #
        #     def call(params)
        #       # ...
        #       raise RecordNotFound.new
        #     end
        #   end
        #
        #   Show.new.call({id: 1}) # => [404, {}, ['Not Found']]
        def handle_exception(exception, status)
          self.handled_exceptions[exception] = status
        end
      end

      protected

      # Throw the given HTTP status code.
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
      # @since 0.1.0
      #
      # @see Lotus::Controller#handled_exceptions
      # @see Lotus::Action::Throwable#handle_exception
      # @see Lotus::Http::Status:ALL
      def throw(code)
        status(*Http::Status.for_code(code))
        super :halt
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
        throw self.class.handled_exceptions.fetch(exception.class, 500)
      end
    end
  end
end
