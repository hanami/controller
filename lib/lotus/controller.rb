require 'lotus/utils/class_attribute'
require 'lotus/action'
require 'lotus/controller/dsl'
require 'lotus/controller/version'
require 'rack-patch'

module Lotus
  # A set of logically grouped actions
  #
  # @since 0.1.0
  #
  # @see Lotus::Action
  #
  # @example
  #   require 'lotus/controller'
  #
  #   class ArticlesController
  #     include Lotus::Controller
  #
  #     action 'Index' do
  #       # ...
  #     end
  #
  #     action 'Show' do
  #       # ...
  #     end
  #   end
  module Controller
    include Utils::ClassAttribute

    # Global handled exceptions.
    # When an handled exception is raised during #call execution, it will be
    # translated into the associated HTTP status.
    #
    # By default there aren't handled exceptions, all the errors are threaded
    # as a Server Side Error (500).
    #
    # **Important:** Be sure to set this configuration, **before** the actions
    # and controllers of your application are loaded.
    #
    # @since 0.1.0
    #
    # @see Lotus::Action::Throwable
    #
    # @example
    #   require 'lotus/controller'
    #
    #   Lotus::Controller.handled_exceptions = { RecordNotFound => 404 }
    #
    #   class Show
    #     include Lotus::Action
    #
    #     def call(params)
    #       # ...
    #       raise RecordNotFound.new
    #     end
    #   end
    #
    #   Show.new.call({id: 1}) # => [404, {}, ['Not Found']]
    class_attribute :handled_exceptions
    self.handled_exceptions = {}

    def self.included(base)
      base.class_eval do
        include Dsl
      end
    end
  end
end

