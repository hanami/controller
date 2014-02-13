module Lotus
  module Action
    # Mime type API
    #
    # @since 0.1.0
    module Mime
      HTTP_ACCEPT          = 'HTTP_ACCEPT'.freeze
      CONTENT_TYPE         = 'Content-Type'.freeze
      DEFAULT_ACCEPT       = '*/*'.freeze
      DEFAULT_CONTENT_TYPE = 'application/octet-stream'.freeze

      protected
      # Finalize the response by setting the current content type
      #
      # @since 0.1.0
      # @api private
      #
      # @see Lotus::Action#finish
      def finish
        super
        headers.merge! CONTENT_TYPE => content_type
      end

      # Sets the given content type
      #
      # Lotus::Action sets the proper content type automatically, this method
      #   is designed to override that value.
      #
      # @param content_type [String] the content type
      # @return [void]
      #
      # @since 0.1.0
      #
      # @see Lotus::Action::Mime#content_type
      #
      # @example
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       self.content_type = 'application/json'
      #     end
      #   end
      def content_type=(content_type)
        @content_type = content_type
      end

      # Read the current content type from the request.
      # This value is automatically set in the response, to override it use
      #   #content_type=
      #
      # @return [String] the content type from the request.
      #
      # @since 0.1.0
      #
      # @see Lotus::Action::Mime#content_type=
      #
      # @example
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       content_type # => 'text/html'
      #     end
      #   end
      def content_type
        @content_type || accepts || DEFAULT_CONTENT_TYPE
      end

      private
      def accepts
        if ( _accept = @_env[HTTP_ACCEPT] ) && _accept != DEFAULT_ACCEPT
          ::Rack::Utils.best_q_match(_accept, ::Rack::Mime::MIME_TYPES.values)
        end
      end
    end
  end
end
