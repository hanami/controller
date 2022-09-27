# frozen_string_literal: true

require "hanami/action"
require "hanami/controller/version"
require "hanami/controller/error"

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
  #   require "hanami/controller"
  #
  #   module Articles
  #     class Index < Hanami::Action
  #       # ...
  #     end
  #
  #     class Show < Hanami::Action
  #       # ...
  #     end
  #   end
  module Controller
    # Unknown format error
    #
    # This error is raised when a action sets a format that it isn't recognized
    # both by `Hanami::Action::Configuration` and the list of Rack mime types
    #
    # @since 0.2.0
    #
    # @see Hanami::Action::Mime#format=
    class UnknownFormatError < Hanami::Controller::Error
      # @since 0.2.0
      # @api private
      def initialize(format)
        super("Cannot find a corresponding Mime type for '#{format}'. Please configure it with Hanami::Controller::Configuration#format.") # rubocop:disable Layout/LineLength
      end
    end
  end
end
