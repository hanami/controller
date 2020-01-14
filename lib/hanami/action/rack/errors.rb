# frozen_string_literal: true

module Hanami
  module Action
    module Rack
      # This module provides method to set exceptions to Rack env:
      #
      #   * `rack.errors` - IO for errors, as requested by Rack SPEC
      #   * `rack.exception` - De-facto standard for Ruby exception tracking SaaS
      #
      # @see http://www.rubydoc.info/github/rack/rack/file/SPEC#The_Error_Stream
      # @see https://github.com/hanami/controller/issues/133
      #
      # @since 1.3.3
      # @api private
      module Errors
        # @since 1.3.3
        # @api private
        RACK_ERRORS = "rack.errors"

        # @since 1.3.3
        # @api private
        RACK_EXCEPTION = "rack.exception"

        # Set exception in Rack env
        #
        # @param env [Hash] the Rack environment
        # @param exception [Exception] the exception to set
        #
        # @since 1.3.3
        # @api private
        def self.set(env, exception)
          env[RACK_EXCEPTION] = exception

          return unless errors = env[RACK_ERRORS] # rubocop:disable Lint/AssignmentInCondition

          errors.write(_dump_exception(exception))
          errors.flush
        end

        # Format exception info with name and backtrace
        #
        # @param exception [Exception]
        #
        # @since 1.3.3
        # @api private
        def self._dump_exception(exception)
          [[exception.class, exception.message].compact.join(": "), *exception.backtrace].join("\n\t")
        end
      end
    end
  end
end
