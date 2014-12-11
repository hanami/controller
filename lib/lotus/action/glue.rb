module Lotus
  module Action
    # Glue code for full stack Lotus applications
    #
    # @api private
    # @since x.x.x
    module Glue
      # Rack environment key that indicates where the action instance is passed
      #
      # @api private
      # @since x.x.x
      ENV_KEY = 'lotus.action'.freeze

      # Override Ruby's Module#included
      #
      # @api private
      # @since x.x.x
      def self.included(base)
        base.class_eval { expose :format }
      end

      protected
      # Put the current instance into the Rack environment
      #
      # @api private
      # @since x.x.x
      #
      # @see Lotus::Action#finish
      def finish
        super
        @_env[ENV_KEY] = self
      end
    end
  end
end
