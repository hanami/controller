module Lotus
  module Action
    module Validatable

      def self.included(base)
        base.class_eval do
          extend ClassMethods
        end
      end

      module ClassMethods
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
        def params(params_class)
          @params_class = params_class
        end

        # Returns the class which defines the params
        #
        # Returns the class which has been provided to define the
        # params.  By default this will be Lotus::Action::Params.
        #
        # @return [Object] return the associated object, if found
        #
        # @since 0.2.0
        def params_class
          @params_class ||= Params
        end

      end
    end
  end
end
