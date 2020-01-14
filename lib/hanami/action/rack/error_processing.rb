# frozen_string_literal: true

module Hanami
  module Action
    module Rack
      # This module provides method for saving exceptions
      # to rack-env:
      # <tt>rack.errors</tt> - for common Rack SPEC
      # <tt>rack.exceptions</tt> - for services which track exceptions
      #
      # @see http://www.rubydoc.info/github/rack/rack/file/SPEC#The_Error_Stream
      # @see https://github.com/hanami/controller/issues/133
      module ErrorProcessing
        RACK_ERRORS = 'rack.errors'

        RACK_EXCEPTION = 'rack.exception'

        # Store exception in rack env
        #
        # @param env rack-env
        # @param exception [Exception]
        def self.save_error_in_rack_env(env, exception)
          env[RACK_EXCEPTION] = exception

          return unless errors = env[RACK_ERRORS] # rubocop:disable Lint/AssignmentInCondition

          errors.write(_dump_exception(exception))
          errors.flush
        end

        # Format exception info with name and backtrace
        #
        # @param exception [Exception]
        def self._dump_exception(exception)
          [[exception.class, exception.message].compact.join(": "), *exception.backtrace].join("\n\t")
        end
      end
    end
  end
end
