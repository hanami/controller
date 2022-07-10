module Hanami
  class Action
    # Glue code for full stack Hanami applications
    #
    # This includes missing rendering logic that it makes sense to include
    # only for web applications.
    #
    # @api private
    # @since 0.3.0
    module Glue
      # Rack environment key that indicates where the action instance is passed
      #
      # @api private
      # @since 0.3.0
      ENV_KEY = "hanami.action".freeze

      protected

      # Put the current instance into the Rack environment
      #
      # @api private
      # @since 0.3.0
      #
      # @see Hanami::Action#finish
      def finish(req, *)
        req.env[ENV_KEY] = self
        super
      end

      # Check if the request's body is a file
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.4.3
      def sending_file?
        response.body.is_a?(::Rack::File::Iterator)
      end
    end
  end
end
