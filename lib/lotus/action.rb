require 'lotus/action/rack'
require 'lotus/action/mime'
require 'lotus/action/redirect'
require 'lotus/action/cookies'
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
    def self.included(base)
      base.class_eval do
        include Rack
        include Mime
        include Redirect
        include Cookies
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
