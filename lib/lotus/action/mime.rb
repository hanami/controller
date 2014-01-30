module Lotus
  module Action
    # Mime type API
    #
    # @since 0.1.0
    module Mime
      CONTENT_TYPE         = 'Content-Type'.freeze
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
      # @see Rack::Request#media_type
      # @see Lotus::HTTP::Request#accepts
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
        @content_type || @_request.media_type || @_request.accepts || DEFAULT_CONTENT_TYPE
      end
    end
  end
end
