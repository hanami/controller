module Lotus
  module Action
    # Glue code for full stack Lotus applications
    #
    # @api private
    # @since 0.3.0
    module Glue
      # Rack environment key that indicates where the action instance is passed
      #
      # @api private
      # @since 0.3.0
      ENV_KEY = 'lotus.action'.freeze

      # Override Ruby's Module#included
      #
      # @api private
      # @since 0.3.0
      def self.included(base)
        base.class_eval { expose :format }
      end

      protected
      # Put the current instance into the Rack environment
      #
      # @api private
      # @since 0.3.0
      #
      # @see Lotus::Action#finish
      def finish
        super
        @_env[ENV_KEY] = self
      end
    end
  end
end
