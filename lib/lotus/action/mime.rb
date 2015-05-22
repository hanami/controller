require 'rack/utils'
require 'lotus/utils'
require 'lotus/utils/kernel'

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
      # @api private
      HTTP_ACCEPT          = 'HTTP_ACCEPT'.freeze

      # The header key to set the mime type of the response
      #
      # @since 0.1.0
      # @api private
      CONTENT_TYPE         = 'Content-Type'.freeze

      # The default mime type for an incoming HTTP request
      #
      # @since 0.1.0
      # @api private
      DEFAULT_ACCEPT       = '*/*'.freeze

      # The default mime type that is returned in the response
      #
      # @since 0.1.0
      # @api private
      DEFAULT_CONTENT_TYPE = 'application/octet-stream'.freeze

      # The default charset that is returned in the response
      #
      # @since 0.3.0
      # @api private
      DEFAULT_CHARSET = 'utf-8'.freeze

      # Override Ruby's hook for modules.
      # It includes Mime types logic
      #
      # @param base [Class] the target action
      #
      # @since 0.1.0
      # @api private
      #
      # @see http://www.ruby-doc.org/core-2.1.2/Module.html#method-i-included
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # @since 0.2.0
        # @api private
        def format_to_mime_type(format)
          configuration.mime_type_for(format) ||
            ::Rack::Mime.mime_type(".#{ format }", nil) or
            raise Lotus::Controller::UnknownFormatError.new(format)
        end

        private

        # Restrict the access to the specified mime type symbols.
        #
        # @param formats[Array<Symbol>] one or more symbols representing mime type(s)
        #
        # @raise [Lotus::Controller::UnknownFormatError] if the symbol cannot
        #   be converted into a mime type
        #
        # @since 0.1.0
        #
        # @see Lotus::Controller::Configuration#format
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
        def accept(*formats)
          mime_types = formats.map do |format|
            format_to_mime_type(format)
          end

          before do
            unless mime_types.find {|mt| accept?(mt) }
              halt 406
            end
          end
        end
      end

      # Returns a symbol representation of the content type.
      #
      # The framework automatically detects the request mime type, and returns
      # the corresponding format.
      #
      # However, if this value was explicitely set by `#format=`, it will return
      # that value
      #
      # @return [Symbol] a symbol that corresponds to the content type
      #
      # @since 0.2.0
      #
      # @see Lotus::Action::Mime#format=
      # @see Lotus::Action::Mime#content_type
      #
      # @example Default scenario
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #     end
      #   end
      #
      #   action = Show.new
      #
      #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => 'text/html' })
      #   headers['Content-Type'] # => 'text/html'
      #   action.format           # => :html
      #
      # @example Set value
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #       self.format = :xml
      #     end
      #   end
      #
      #   action = Show.new
      #
      #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => 'text/html' })
      #   headers['Content-Type'] # => 'application/xml'
      #   action.format           # => :xml
      def format
        @format ||= detect_format
      end

      # The content type that will be automatically set in the response.
      #
      # It prefers, in order:
      #   * Explicit set value (see #format=)
      #   * Weighted value from Accept
      #   * Default content type
      #
      # To override the value, use <tt>#format=</tt>
      #
      # @return [String] the content type from the request.
      #
      # @since 0.1.0
      #
      # @see Lotus::Action::Mime#format=
      # @see Lotus::Configuration#default_format
      # @see Lotus::Action::Mime#default_content_type
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
        @content_type || accepts || default_content_type || DEFAULT_CONTENT_TYPE
      end

      # Action charset setter, receives new charset value
      #
      # @return [String] the charset of the request.
      #
      # @since 0.3.0
      #
      # @example
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       self.charset = 'koi8-r'
      #     end
      #   end
      def charset=(value)
        @charset = value
      end

      # The charset that will be automatically set in the response.
      #
      # It prefers, in order:
      #   * Explicit set value (see #charset=)
      #   * Default configuration charset
      #   * Default content type
      #
      # To override the value, use <tt>#charset=</tt>
      #
      # @return [String] the charset of the request.
      #
      # @since 0.3.0
      #
      # @see Lotus::Action::Mime#charset=
      # @see Lotus::Configuration#default_charset
      # @see Lotus::Action::Mime#default_charset
      # @see Lotus::Action::Mime#DEFAULT_CHARSET
      #
      # @example
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       charset # => 'text/html'
      #     end
      #   end
      def charset
        @charset || default_charset || DEFAULT_CHARSET
      end

      private

      # Finalize the response by setting the current content type
      #
      # @since 0.1.0
      # @api private
      #
      # @see Lotus::Action#finish
      def finish
        super
        headers[CONTENT_TYPE] ||= content_type_with_charset
      end

      # Sets the given format and corresponding content type.
      #
      # The framework detects the `HTTP_ACCEPT` header of the request and sets
      # the proper `Content-Type` header in the response.
      # Within this default scenario, `#format` returns a symbol that
      # corresponds to `#content_type`.
      # For instance, if a client sends an `HTTP_ACCEPT` with `text/html`,
      # `#content_type` will return `text/html` and `#format` `:html`.
      #
      # However, it's possible to override what the framework have detected.
      # If a client asks for an `HTTP_ACCEPT` `*/*`, but we want to force the
      # response to be a `text/html` we can use this method.
      #
      # When the format is set, the framework searchs for a corresponding mime
      # type to be set as the `Content-Type` header of the response.
      # This lookup is performed first in the configuration, and then in
      # `Rack::Mime::MIME_TYPES`. If the lookup fails, it raises an error.
      #
      # PERFORMANCE: Because `Lotus::Controller::Configuration#formats` is
      # smaller and looked up first than `Rack::Mime::MIME_TYPES`, we suggest to
      # configure the most common mime types used by your application, **even
      # if they are already present in that Rack constant**.
      #
      # @param format [#to_sym] the format
      #
      # @return [void]
      #
      # @raise [TypeError] if the format cannot be coerced into a Symbol
      # @raise [Lotus::Controller::UnknownFormatError] if the format doesn't
      #   have a corresponding mime type
      #
      # @since 0.2.0
      #
      # @see Lotus::Action::Mime#format
      # @see Lotus::Action::Mime#content_type
      # @see Lotus::Controller::Configuration#format
      #
      # @example Default scenario
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #     end
      #   end
      #
      #   action = Show.new
      #
      #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => '*/*' })
      #   headers['Content-Type'] # => 'application/octet-stream'
      #   action.format           # => :all
      #
      #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => 'text/html' })
      #   headers['Content-Type'] # => 'text/html'
      #   action.format           # => :html
      #
      # @example Simple usage
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       self.format = :json
      #     end
      #   end
      #
      #   action = Show.new
      #
      #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => '*/*' })
      #   headers['Content-Type'] # => 'application/json'
      #   action.format           # => :json
      #
      # @example Unknown format
      #   require 'lotus/controller'
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       self.format = :unknown
      #     end
      #   end
      #
      #   action = Show.new
      #   action.call({ 'HTTP_ACCEPT' => '*/*' })
      #     # => raise Lotus::Controller::UnknownFormatError
      #
      # @example Custom mime type/format
      #   require 'lotus/controller'
      #
      #   Lotus::Controller.configure do
      #     format :custom, 'application/custom'
      #   end
      #
      #   class Show
      #     include Lotus::Action
      #
      #     def call(params)
      #       # ...
      #       self.format = :custom
      #     end
      #   end
      #
      #   _, headers, _ = action.call({ 'HTTP_ACCEPT' => '*/*' })
      #   headers['Content-Type'] # => 'application/custom'
      #   action.format           # => :custom
      def format=(format)
        @format       = Utils::Kernel.Symbol(format)
        @content_type = self.class.format_to_mime_type(@format)
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

      # @since 0.1.0
      # @api private
      def accept
        @accept ||= @_env[HTTP_ACCEPT] || DEFAULT_ACCEPT
      end

      # @since 0.1.0
      # @api private
      def accepts
        unless accept == DEFAULT_ACCEPT
          best_q_match(accept, ::Rack::Mime::MIME_TYPES.values)
        end
      end

      # @since 0.2.0
      # @api private
      def default_content_type
        self.class.format_to_mime_type(
          configuration.default_format
        ) if configuration.default_format
      end

      # @since 0.2.0
      # @api private
      def detect_format
        configuration.format_for(content_type) ||
          ::Rack::Mime::MIME_TYPES.key(content_type).gsub(/\A\./, '').to_sym
      end

      # @since 0.3.0
      # @api private
      def default_charset
        configuration.default_charset
      end

      # @since 0.3.0
      # @api private
      def content_type_with_charset
        "#{content_type}; charset=#{charset}"
      end

      # Patched version of <tt>Rack::Utils.best_q_match</tt>.
      #
      # @since 0.4.1
      # @api private
      #
      # @see http://www.rubydoc.info/gems/rack/Rack/Utils#best_q_match-class_method
      # @see https://github.com/rack/rack/pull/659
      # @see https://github.com/lotus/controller/issues/59
      # @see https://github.com/lotus/controller/issues/104
      def best_q_match(q_value_header, available_mimes)
        values = ::Rack::Utils.q_values(q_value_header)

        values = values.map do |req_mime, quality|
          match = available_mimes.find { |am| ::Rack::Mime.match?(am, req_mime) }
          next unless match
          [match, quality]
        end.compact

        # See https://github.com/lotus/controller/issues/59
        # See https://github.com/lotus/controller/issues/104
        values = values.reverse unless Lotus::Utils.jruby?

        value  = values.sort_by do |match, quality|
          (match.split('/', 2).count('*') * -10) + quality
        end.last

        value.first if value
      end
    end
  end
end
