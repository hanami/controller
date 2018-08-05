# frozen_string_literal: true

require "hanami/action/configurable"
require "hanami/action/rack"
require "hanami/action/mime"
require "hanami/action/redirect"
require "hanami/action/exposable"
require "hanami/action/throwable"
require "hanami/action/callbacks"
begin
  require "hanami/validations"
  require "hanami/action/validatable"
rescue LoadError # rubocop:disable Lint/HandleExceptions
end
require "hanami/action/head"
require "hanami/action/callable"

module Hanami
  # An HTTP endpoint
  #
  # @since 0.1.0
  #
  # @example
  #   require 'hanami/controller'
  #
  #   class Show
  #     include Hanami::Action
  #
  #     def call(params)
  #       # ...
  #     end
  #   end
  module Action
    # Override Ruby's hook for modules.
    # It includes basic Hanami::Action modules to the given class.
    #
    # @param base [Class] the target action
    #
    # @since 0.1.0
    # @api private
    #
    # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
    #
    # @see Hanami::Action::Rack
    # @see Hanami::Action::Mime
    # @see Hanami::Action::Http
    # @see Hanami::Action::Redirect
    # @see Hanami::Action::Exposable
    # @see Hanami::Action::Throwable
    # @see Hanami::Action::Callbacks
    # @see Hanami::Action::Validatable
    # @see Hanami::Action::Configurable
    # @see Hanami::Action::Callable
    def self.included(base) # rubocop:disable Metrics/MethodLength
      base.class_eval do
        include Rack
        include Mime
        include Redirect
        include Exposable
        include Throwable
        include Callbacks
        include Validatable if defined?(Validatable)
        include Configurable
        include Head
        prepend Callable
      end
    end

    private

    # Raise error when `Hanami::Action::Session` isn't included.
    #
    # To use `session`, include `Hanami::Action::Session`.
    #
    # @raise [Hanami::Controller::MissingSessionError]
    #
    # @since 1.2.0
    def session
      raise Hanami::Controller::MissingSessionError.new(:session)
    end

    # Raise error when `Hanami::Action::Session` isn't included.
    #
    # To use `flash`, include `Hanami::Action::Session`.
    #
    # @raise [Hanami::Controller::MissingSessionError]
    #
    # @since 1.2.0
    def flash
      raise Hanami::Controller::MissingSessionError.new(:flash)
    end

    # Finalize the response
    #
    # This method is abstract and COULD be implemented by included modules in
    # order to prepare their data before the response will be returned to the
    # webserver.
    #
    # @since 0.1.0
    # @api private
    # @abstract
    #
    # @see Hanami::Action::Mime#finish
    # @see Hanami::Action::Exposable#finish
    # @see Hanami::Action::Callable#finish
    # @see Hanami::Action::Session#finish
    # @see Hanami::Action::Cookies#finish
    # @see Hanami::Action::Cache#finish
    # @see Hanami::Action::Head#finish
    def finish
    end
  end
end
