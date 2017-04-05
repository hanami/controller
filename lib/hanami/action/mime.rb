require 'rack/utils'
require 'hanami/utils'
require 'hanami/utils/kernel'

module Hanami
  module Action
    # Mime type API
    #
    # @since 0.1.0
    #
    # @see Hanami::Action::Mime::ClassMethods#accept
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

      # Most commom MIME Types used for responses
      #
      # @since 1.0.0
      # @api private
      MIME_TYPES = {
        txt: 'text/plain',
        html: 'text/html',
        json: 'application/json',
        manifest: 'text/cache-manifest',
        atom: 'application/atom+xml',
        avi: 'video/x-msvideo',
        bmp: 'image/bmp',
        bz: 'application/x-bzip',
        bz2: 'application/x-bzip2',
        chm: 'application/vnd.ms-htmlhelp',
        css: 'text/css',
        csv: 'text/csv',
        flv: 'video/x-flv',
        gif: 'image/gif',
        gz: 'application/x-gzip',
        h264: 'video/h264',
        ico: 'image/vnd.microsoft.icon',
        ics: 'text/calendar',
        jpg: 'image/jpeg',
        js: 'application/javascript',
        mp4: 'video/mp4',
        mov: 'video/quicktime',
        mp3: 'audio/mpeg',
        mp4a: 'audio/mp4',
        mpg: 'video/mpeg',
        oga: 'audio/ogg',
        ogg: 'application/ogg',
        ogv: 'video/ogg',
        pdf: 'application/pdf',
        pgp: 'application/pgp-encrypted',
        png: 'image/png',
        psd: 'image/vnd.adobe.photoshop',
        rtf: 'application/rtf',
        sh: 'application/x-sh',
        svg: 'image/svg+xml',
        swf: 'application/x-shockwave-flash',
        tar: 'application/x-tar',
        torrent: 'application/x-bittorrent',
        tsv: 'text/tab-separated-values',
        uri: 'text/uri-list',
        vcs: 'text/x-vcalendar',
        wav: 'audio/x-wav',
        webm: 'video/webm',
        wmv: 'video/x-ms-wmv',
        woff: 'application/font-woff',
        woff2: 'application/font-woff2',
        wsdl: 'application/wsdl+xml',
        xhtml: 'application/xhtml+xml',
        xml: 'application/xml',
        xslt: 'application/xslt+xml',
        yml: 'text/yaml',
        zip: 'application/zip' }.freeze

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
        base.class_eval do
          extend ClassMethods
          prepend InstanceMethods
        end
      end

      module ClassMethods
        # @since 0.2.0
        # @api private
        def format_to_mime_type(format)
          configuration.mime_type_for(format) ||
            MIME_TYPES[format] or
            raise Hanami::Controller::UnknownFormatError.new(format)
        end

        private

        # Restrict the access to the specified mime type symbols.
        #
        # @param formats[Array<Symbol>] one or more symbols representing mime type(s)
        #
        # @raise [Hanami::Controller::UnknownFormatError] if the symbol cannot
        #   be converted into a mime type
        #
        # @since 0.1.0
        #
        # @see Hanami::Controller::Configuration#format
        #
        # @example
        #   require 'hanami/controller'
        #
        #   class Show
        #     include Hanami::Action
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

          configuration.restrict_mime_types!(mime_types)

          before do
            unless mime_types.find {|mt| accept?(mt) }
              halt 406
            end
          end
        end
      end

      # @since 0.7.0
      # @api private
      module InstanceMethods
        # @since 0.7.0
        # @api private
        def initialize(*)
          super
          @content_type = nil
          @charset      = nil
        end
      end

      # Returns a symbol representation of the content type.
      #
      # The framework automatically detects the request mime type, and returns
      # the corresponding format.
      #
      # However, if this value was explicitly set by `#format=`, it will return
      # that value
      #
      # @return [Symbol] a symbol that corresponds to the content type
      #
      # @since 0.2.0
      #
      # @see Hanami::Action::Mime#format=
      # @see Hanami::Action::Mime#content_type
      #
      # @example Default scenario
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
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
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
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
      #   * Explicit set value (see Hanami::Action::Mime#format=)
      #   * Weighted value from Accept header based on all known MIME Types:
      #     - Custom registered MIME Types (see Hanami::Controller::Configuration#format)
      #   * Configured default content type (see Hanami::Controller::Configuration#default_response_format)
      #   * Hard-coded default content type (see Hanami::Action::Mime::DEFAULT_CONTENT_TYPE)
      #
      # To override the value, use <tt>#format=</tt>
      #
      # @return [String] the content type from the request.
      #
      # @since 0.1.0
      #
      # @see Hanami::Action::Mime#format=
      # @see Hanami::Configuration#default_request_format
      # @see Hanami::Action::Mime#default_content_type
      # @see Hanami::Action::Mime#DEFAULT_CONTENT_TYPE
      # @see Hanami::Controller::Configuration#format
      # @see Hanami::Controller::Configuration#default_response_format
      #
      # @example
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #
      #     def call(params)
      #       # ...
      #       content_type # => 'text/html'
      #     end
      #   end
      def content_type
        return @content_type unless @content_type.nil?

        if accept_header?
          type = content_type_from_accept_header
          return type if type
        end

        default_response_type || default_content_type || DEFAULT_CONTENT_TYPE
      end

      # Action charset setter, receives new charset value
      #
      # @return [String] the charset of the request.
      #
      # @since 0.3.0
      #
      # @example
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
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
      # @see Hanami::Action::Mime#charset=
      # @see Hanami::Configuration#default_charset
      # @see Hanami::Action::Mime#default_charset
      # @see Hanami::Action::Mime#DEFAULT_CHARSET
      #
      # @example
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
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
      # @see Hanami::Action#finish
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
      # When the format is set, the framework searches for a corresponding mime
      # type to be set as the `Content-Type` header of the response.
      # This lookup is performed first in the configuration, and then in
      # `Hanami::Action::Mime::MIME_TYPES`. If the lookup fails, it raises an error.
      #
      # PERFORMANCE: Because `Hanami::Controller::Configuration#formats` is
      # smaller and looked up first than `Hanami::Action::Mime::MIME_TYPES`,
      # we suggest to configure the most common mime types used by your
      # application, **even if they are already present in that Rack constant**.
      #
      # @param format [#to_sym] the format
      #
      # @return [void]
      #
      # @raise [TypeError] if the format cannot be coerced into a Symbol
      # @raise [Hanami::Controller::UnknownFormatError] if the format doesn't
      #   have a corresponding mime type
      #
      # @since 0.2.0
      #
      # @see Hanami::Action::Mime#format
      # @see Hanami::Action::Mime#content_type
      # @see Hanami::Controller::Configuration#format
      #
      # @example Default scenario
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
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
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
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
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
      #
      #     def call(params)
      #       # ...
      #       self.format = :unknown
      #     end
      #   end
      #
      #   action = Show.new
      #   action.call({ 'HTTP_ACCEPT' => '*/*' })
      #     # => raise Hanami::Controller::UnknownFormatError
      #
      # @example Custom mime type/format
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     format :custom, 'application/custom'
      #   end
      #
      #   class Show
      #     include Hanami::Action
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
      #   require 'hanami/controller'
      #
      #   class Show
      #     include Hanami::Action
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

      # @since 0.1.0
      # @api private
      def accept
        @accept ||= @_env[HTTP_ACCEPT] || DEFAULT_ACCEPT
      end

      # Checks if there is an Accept header for the current request.
      #
      # @return [TrueClass,FalseClass] the result of the check
      #
      # @since 0.8.0
      # @api private
      def accept_header?
        accept != DEFAULT_ACCEPT
      end

      # Look at the Accept header for the current request and see if it
      # matches any of the common MIME types (see Hanami::Action::Mime#MIME_TYPES)
      # or the custom registered ones (see Hanami::Controller::Configuration#format).
      #
      # @return [String,Nil] The matched MIME type for the given Accept header.
      #
      # @since 0.8.0
      # @api private
      #
      # @see Hanami::Action::Mime#MIME_TYPES
      # @see Hanami::Controller::Configuration#format
      #
      # @api private
      def content_type_from_accept_header
        best_q_match(accept, configuration.mime_types)
      end

      # @since 0.5.0
      # @api private
      def default_response_type
        self.class.format_to_mime_type(configuration.default_response_format) if configuration.default_response_format
      end

      # @since 0.2.0
      # @api private
      def default_content_type
        self.class.format_to_mime_type(
          configuration.default_request_format
        ) if configuration.default_request_format
      end

      # @since 0.2.0
      # @api private
      def detect_format
        configuration.format_for(content_type) || MIME_TYPES.key(content_type)
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
      # @see https://github.com/hanami/controller/issues/59
      # @see https://github.com/hanami/controller/issues/104
      def best_q_match(q_value_header, available_mimes)
        values = ::Rack::Utils.q_values(q_value_header)
        values = values.map do |req_mime, quality|
          if req_mime == DEFAULT_ACCEPT
            # See https://github.com/hanami/controller/issues/167
            match = default_content_type
          else
            match = available_mimes.find { |am| ::Rack::Mime.match?(am, req_mime) }
          end
          next unless match
          [match, quality]
        end.compact

        if Hanami::Utils.jruby?
          # See https://github.com/hanami/controller/issues/59
          # See https://github.com/hanami/controller/issues/104
          values.reverse!
        else
          # See https://github.com/jruby/jruby/issues/3004
          values.sort!
        end

        value = values.sort_by do |match, quality|
          (match.split('/'.freeze, 2).count('*'.freeze) * -10) + quality
        end.last

        value.first if value
      end
    end
  end
end
