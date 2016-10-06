require 'hanami/utils/class_attribute'
require 'hanami/action'
require 'hanami/controller/configuration'
require 'hanami/controller/version'
require 'hanami/controller/error'

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
      def initialize(format)
        super("Cannot find a corresponding Mime type for '#{ format }'. Please configure it with Hanami::Controller::Configuration#format.")
      end
    end

    def self.included(base)
      base.class_eval do
        include Utils::ClassAttribute

        class_attribute :configuration
        self.configuration = Configuration.new

        extend ClassMethods
      end
    end

    module ClassMethods
      private

      def configure(&blk)
        self.configuration = Configuration.new(&blk)
      end
    end

    # Framework loading entry point
    #
    # @return [void]
    #
    # @since 0.3.0
    def self.load!
      configuration.load!
    end
  end
end

