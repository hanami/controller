require 'hanami/utils/class_attribute'
require 'hanami/action'
require 'hanami/controller/configuration'
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

    include Utils::ClassAttribute

    # Framework configuration
    #
    # @since 0.2.0
    # @api private
    class_attribute :configuration
    self.configuration = Configuration.new

    # Configure the framework.
    # It yields the given block in the context of the configuration
    #
    # @param blk [Proc] the configuration block
    #
    # @since 0.2.0
    #
    # @see Hanami::Controller::Configuration
    #
    # @example
    #   require 'hanami/controller'
    #
    #   Hanami::Controller.configure do
    #     handle_exceptions false
    #   end
    def self.configure
      yield configuration
    end
  end
end
