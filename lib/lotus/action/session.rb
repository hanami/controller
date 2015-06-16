require 'lotus/action/flash'

module Lotus
  module Action
    # Session API
    #
    # This module isn't included by default.
    #
    # @since 0.1.0
    module Session
      # The key that returns raw session from the Rack env
      #
      # @since 0.1.0
      # @api private
      SESSION_KEY = 'rack.session'.freeze

      # The key that is used by flash to transport errors
      #
      # @since 0.3.0
      # @api private
      ERRORS_KEY  = :__errors

      # Add session to default exposures
      #
      # @since 0.4.4
      # @api private
      def self.included(action)
        action.class_eval do
          expose :session
        end
      end

      protected

      # Gets the session from the request and expose it as an Hash.
      #
      # @return [Hash] the HTTP session from the request
      #
      # @since 0.1.0
      #
      # @example
      #   require 'lotus/controller'
      #   require 'lotus/action/session'
      #
      #   class Show
      #     include Lotus::Action
      #     include Lotus::Action::Session
      #
      #     def call(params)
      #       # ...
      #
      #       # get a value
      #       session[:user_id] # => '23'
      #
      #       # set a value
      #       session[:foo] = 'bar'
      #
      #       # remove a value
      #       session[:bax] = nil
      #     end
      #   end
      def session
        @_env[SESSION_KEY] ||= {}
      end

      private

      # Container useful to transport data with the HTTP session
      #
      # @return [Lotus::Action::Flash] a Flash instance
      #
      # @since 0.3.0
      # @api private
      #
      # @see Lotus::Action::Flash
      def flash
        @flash ||= Flash.new(session, request_id)
      end

      # In case of validations errors, preserve those informations after a
      # redirect.
      #
      # @return [void]
      #
      # @since 0.3.0
      # @api private
      #
      # @see Lotus::Action::Redirect#redirect_to
      #
      # @example
      #   require 'lotus/controller'
      #
      #   module Comments
      #     class Index
      #       include Lotus::Action
      #       include Lotus::Action::Session
      #
      #       expose :comments
      #
      #       def call(params)
      #         @comments = CommentRepository.all
      #       end
      #     end
      #
      #     class Create
      #       include Lotus::Action
      #       include Lotus::Action::Session
      #
      #       params do
      #         param :text, type: String, presence: true
      #       end
      #
      #       def call(params)
      #         comment = Comment.new(params)
      #         CommentRepository.create(comment) if params.valid?
      #
      #         redirect_to '/comments'
      #       end
      #     end
      #   end
      #
      #   # The validation errors caused by Comments::Create are available
      #   # **after the redirect** in the context of Comments::Index.
      def redirect_to(*args)
        flash[ERRORS_KEY] = errors.to_a unless params.valid?
        super
      end

      # Read errors from flash or delegate to the superclass
      #
      # @return [Lotus::Validations::Errors] A collection of validation errors
      #
      # @since 0.3.0
      # @api private
      #
      # @see Lotus::Action::Validatable
      # @see Lotus::Action::Session#flash
      def errors
        flash[ERRORS_KEY] || super
      end

      # Finalize the response
      #
      # @return [void]
      #
      # @since 0.3.0
      # @api private
      #
      # @see Lotus::Action#finish
      def finish
        super
        flash.clear
      end
    end
  end
end
