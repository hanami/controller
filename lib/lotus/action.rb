require 'lotus/utils/class_attribute'
require 'lotus/action/rack'
require 'lotus/action/mime'
require 'lotus/action/redirect'
require 'lotus/action/exposable'
require 'lotus/action/throwable'
require 'lotus/action/callbacks'
require 'lotus/action/callable'

module Lotus
  # An HTTP endpoint
  #
  # @since 0.1.0
  #
  # @example
  #   require 'lotus/controller'
  #
  #   class Show
  #     include Lotus::Action
  #
  #     def call(params)
  #       # ...
  #     end
  #   end
  module Action
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
    #   require 'lotus/action'
    #
    #   Lotus::Action.handled_exceptions = { RecordNotFound => 404 }
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
        include Rack
        include Mime
        include Redirect
        include Exposable
        include Throwable
        include Callbacks
        prepend Callable
      end
    end

    protected

    # Finalize the response
    #
    # This method is abstract and COULD be implemented by included modules in
    # order to prepare their data before the reponse will be returned to the
    # webserver.
    #
    # @since 0.1.0
    # @api private
    # @abstract
    #
    # @see Lotus::Action::Mime
    # @see Lotus::Action::Cookies
    # @see Lotus::Action::Callable
    def finish
    end
  end
end
