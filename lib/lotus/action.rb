require 'lotus/action/configurable'
require 'lotus/action/rack'
require 'lotus/action/mime'
require 'lotus/action/redirect'
require 'lotus/action/exposable'
require 'lotus/action/throwable'
require 'lotus/action/callbacks'
require 'lotus/action/validatable'
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
    # Override Ruby's hook for modules.
    # It includes basic Lotus::Action modules to the given class.
    #
    # @param base [Class] the target action
    #
    # @since 0.1.0
    # @api private
    #
    # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
    #
    # @see Lotus::Action::Rack
    # @see Lotus::Action::Mime
    # @see Lotus::Action::Redirect
    # @see Lotus::Action::Exposable
    # @see Lotus::Action::Throwable
    # @see Lotus::Action::Callbacks
    # @see Lotus::Action::Validatable
    # @see Lotus::Action::Configurable
    # @see Lotus::Action::Callable
    def self.included(base)
      base.class_eval do
        include Rack
        include Mime
        include Redirect
        include Exposable
        include Throwable
        include Callbacks
        include Validatable
        include Configurable
        prepend Callable
      end
    end

    private

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
    # @see Lotus::Action::Cache
    def finish
    end


  end
end
