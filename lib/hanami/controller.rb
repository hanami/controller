require 'hanami/action'
require 'hanami/controller/version'
require 'hanami/controller/error'

# Hanami
#
# @since 0.1.0
module Hanami
  # A set of logically grouped actions
  #
  # @since 0.1.0
  #
  # @see Hanami::Action
  #
  # @example
  #   require 'hanami/controller'
  #
  #   module Articles
  #     class Index
  #       include Hanami::Action
  #
  #       # ...
  #     end
  #
  #     class Show
  #       include Hanami::Action
  #
  #       # ...
  #     end
  #   end
  module Controller
    # Unknown format error
    #
    # This error is raised when a action sets a format that it isn't recognized
    # both by `Hanami::Controller::Configuration` and the list of Rack mime types
    #
    # @since 0.2.0
    #
    # @see Hanami::Action::Mime#format=
    class UnknownFormatError < Hanami::Controller::Error
      # @since 0.2.0
      # @api private
      def initialize(format)
        super("Cannot find a corresponding Mime type for '#{ format }'. Please configure it with Hanami::Controller::Configuration#format.")
      end
    end

    # Missing session error
    #
    # This error is raised when an action sends either `session` or `flash` to
    # itself and it does not include `Hanami::Action::Session`.
    #
    # @since 1.2.0
    #
    # @see Hanami::Action::Session
    # @see Hanami::Action#session
    # @see Hanami::Action#flash
    class MissingSessionError < Hanami::Controller::Error
      def initialize(session_method)
        super("To use `#{session_method}', add `include Hanami::Action::Session`.")
      end
    end
  end
end
