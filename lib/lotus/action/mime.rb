module Lotus
  module Action
    # Mime type API
    #
    # @since 0.1.0
    #
    # @see Lotus::Action::Mime::ClassMethods#accept
    module Mime
      # The key that returns accepted mime types from the Rack env
      #
      # @since 0.1.0
      HTTP_ACCEPT          = 'HTTP_ACCEPT'.freeze

      # The header key to set the mime type of the response
      #
      # @since 0.1.0
      CONTENT_TYPE         = 'Content-Type'.freeze

      # The default mime type for an incoming HTTP request
      #
      # @since 0.1.0
      DEFAULT_ACCEPT       = '*/*'.freeze

      # The default mime type that is returned in the response
      #
      # @since 0.1.0
      DEFAULT_CONTENT_TYPE = 'application/octet-stream'.freeze

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        protected

        # Restrict the access to the specified mime type symbols.
        #
        # @param mime_types[Array<Symbol>] one or more symbols representing mime type(s)
        #
        # @since 0.1.0
        #
        # @example
        #   require 'lotus/controller'
        #
        #   class Show
        #     include Lotus::Action
        #     accept :html, :json
        #
        #     def call(params)
        #       # ...
        #     end
        #   end
        #
        #   # When called with "*/*"              => 200
        #   # When called with "text/html"        => 200
        #   # When called with "application/json" => 200
        #   # When called with "application/xml"  => 406
        def accept(*mime_types)
          mime_types = mime_types.map do |mt|
            ::Rack::Mime.mime_type ".#{ mt }"
          end

          before do
            unless mime_types.find {|mt| accept?(mt) }
              halt 406
            end
          end
        end
      end

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

      # The content type that will be automatically set in the response.
      #
      # It prefers, in order:
      #   * Explicit set value (see #content_type=)
      #   * Weighted value from Accept
      #   * Default content type
      #
      # To override the value, use <tt>#content_type=</tt>
      #
      # @return [String] the content type from the request.
      #
      # @since 0.1.0
      #
      # @see Lotus::Action::Mime#content_type=
      # @see Lotus::Action::Mime#DEFAULT_CONTENT_TYPE
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

      # Match the given mime type with the Accept header
      #
      # @return [Boolean] true if the given mime type matches Accept
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
      #       # @_env['HTTP_ACCEPT'] # => 'text/html,application/xhtml+xml,application/xml;q=0.9'
      #
      #       accept?('text/html')        # => true
      #       accept?('application/xml')  # => true
      #       accept?('application/json') # => false
      #
      #
      #
      #       # @_env['HTTP_ACCEPT'] # => '*/*'
      #
      #       accept?('text/html')        # => true
      #       accept?('application/xml')  # => true
      #       accept?('application/json') # => true
      #     end
      #   end
      def accept?(mime_type)
        !!::Rack::Utils.q_values(accept).find do |mime, _|
          ::Rack::Mime.match?(mime_type, mime)
        end
      end

      private
      def accept
        @accept ||= @_env[HTTP_ACCEPT] || DEFAULT_ACCEPT
      end

      def accepts
        unless accept == DEFAULT_ACCEPT
          ::Rack::Utils.best_q_match(accept, ::Rack::Mime::MIME_TYPES.values)
        end
      end
    end
  end
end
