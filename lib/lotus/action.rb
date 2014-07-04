require 'lotus/action/configurable'
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
    # @see Lotus::Action::Configurable
    # @see Lotus::Action::Rack
    # @see Lotus::Action::Mime
    # @see Lotus::Action::Redirect
    # @see Lotus::Action::Exposable
    # @see Lotus::Action::Throwable
    # @see Lotus::Action::Callbacks
    # @see Lotus::Action::Callable
    def self.included(base)
      base.class_eval do
        include Configurable
        include Rack
        include Mime
        include Redirect
        include Exposable
        include Throwable
        include Callbacks
        prepend Callable

        # Define valid parameters to be passed to #call
        #
        # Uses the specific class to define the parameters which
        # will ultimately be passed to Lotus::Action#call.
        #
        # Any parameters definited by this class will be whitelisted
        # and all other ignored.  If no parameters are defined then
        # all params are whitelisted.
        #
        # @example
        #
        #   class Signup
        #     include Lotus::Action
        #     params SignupParams
        #
        #     def call(params)
        #       params.class   # => SignupParams
        #       params[:email] # => 'foo@example.com'
        #       params[:admin] # => nil
        #     end
        #   end
        #
        #   class SignupParams < Lotus::Action::Params
        #     param :first_name
        #     param :last_name
        #     param :email
        #   end
        #
        # @return [nil] return nil
        #
        # @since 0.2.0
        #
        # @see Lotus::Action::Params
        def self.params(params_class)
          self.params_class = params_class
        end

        def self.params_class=(params_class)
          @params_class = params_class
        end
        private_class_method :params_class=

        # Returns the class which defines the params
        #
        # Returns the class which has been provided to define the
        # params.  By default this will be Lotus::Action::Params.
        #
        # @return [Object] return the associated object, if found
        #
        # @since 0.2.0
        def self.params_class
          @params_class ||= Params
        end

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
