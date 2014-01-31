module Lotus
  module Action
    # Mime type API
    #
    # @since 0.1.0
    module Mime
      CONTENT_TYPE         = 'Content-Type'.freeze
      ENV_CONTENT_TYPE     = 'CONTENT_TYPE'.freeze
      ENV_HTTP_ACCEPT      = 'HTTP_ACCEPT'.freeze
      DEFAULT_CONTENT_TYPE = 'application/octet-stream'.freeze
      CONTENT_TYPE_REGEX   = /\s*[;,]\s*/.freeze

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
        @content_type || media_type || accepts || DEFAULT_CONTENT_TYPE
      end

      private
      def _raw_content_type
        content_type = @_env[ENV_CONTENT_TYPE]
        content_type.nil? || content_type.empty? ? nil : content_type
      end

      def media_type
        _raw_content_type && _raw_content_type.split(CONTENT_TYPE_REGEX, 2).first.downcase
      end

      # FIXME I don't have the time to fix this hack now.
      # FIXME I'm not sure I want to use this API at all.
      def accepts
        accept == '*/*' ? nil : accept
      end

      # TODO order according mime type weight (eg. q=0.8)
      def accept
        if _accept = @_env[ENV_HTTP_ACCEPT]
          _accept.split(',').first
        else
          '*/*'
        end
      end
    end
  end
end
