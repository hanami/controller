# frozen_string_literal: true

require "hanami/utils"
require "rack/utils"
require "rack/mime"

module Hanami
  class Action
    module Mime # rubocop:disable Metrics/ModuleLength
      # Most commom MIME Types used for responses
      #
      # @since 1.0.0
      # @api private
      TYPES = {
        txt: "text/plain",
        html: "text/html",
        json: "application/json",
        manifest: "text/cache-manifest",
        atom: "application/atom+xml",
        avi: "video/x-msvideo",
        bmp: "image/bmp",
        bz: "application/x-bzip",
        bz2: "application/x-bzip2",
        chm: "application/vnd.ms-htmlhelp",
        css: "text/css",
        csv: "text/csv",
        flv: "video/x-flv",
        gif: "image/gif",
        gz: "application/x-gzip",
        h264: "video/h264",
        ico: "image/vnd.microsoft.icon",
        ics: "text/calendar",
        jpg: "image/jpeg",
        js: "application/javascript",
        mp4: "video/mp4",
        mov: "video/quicktime",
        mp3: "audio/mpeg",
        mp4a: "audio/mp4",
        mpg: "video/mpeg",
        oga: "audio/ogg",
        ogg: "application/ogg",
        ogv: "video/ogg",
        pdf: "application/pdf",
        pgp: "application/pgp-encrypted",
        png: "image/png",
        psd: "image/vnd.adobe.photoshop",
        rss: "application/rss+xml",
        rtf: "application/rtf",
        sh: "application/x-sh",
        svg: "image/svg+xml",
        swf: "application/x-shockwave-flash",
        tar: "application/x-tar",
        torrent: "application/x-bittorrent",
        tsv: "text/tab-separated-values",
        uri: "text/uri-list",
        vcs: "text/x-vcalendar",
        wav: "audio/x-wav",
        webm: "video/webm",
        wmv: "video/x-ms-wmv",
        woff: "application/font-woff",
        woff2: "application/font-woff2",
        wsdl: "application/wsdl+xml",
        xhtml: "application/xhtml+xml",
        xml: "application/xml",
        xslt: "application/xslt+xml",
        yml: "text/yaml",
        zip: "application/zip"
      }.freeze

      # @since 2.0.0
      # @api private
      def self.content_type_with_charset(content_type, charset)
        "#{content_type}; charset=#{charset}"
      end

      # Use for setting Content-Type
      # If the request has the ACCEPT header it will try to return the best Content-Type based
      # on the content of the ACCEPT header taking in consideration the weights
      #
      # If no ACCEPT header it will check the default response_format, then the default request format and
      # lastly it will fallback to DEFAULT_CONTENT_TYPE
      #
      # @return [String]
      #
      # @since 2.0.0
      # @api private
      def self.content_type(configuration, request, accepted_mime_types)
        if request.accept_header?
          type = best_q_match(request.accept, accepted_mime_types)
          return type if type
        end

        default_response_type(configuration) || default_content_type(configuration) || Action::DEFAULT_CONTENT_TYPE
      end

      # @since 2.0.0
      # @api private
      def self.charset(default_charset)
        default_charset || Action::DEFAULT_CHARSET
      end

      # @since 2.0.0
      # @api private
      def self.default_response_type(configuration)
        format_to_mime_type(configuration.default_response_format, configuration)
      end

      # @since 2.0.0
      # @api private
      def self.default_content_type(configuration)
        format_to_mime_type(configuration.default_request_format, configuration)
      end

      # @since 2.0.0
      # @api private
      def self.format_to_mime_type(format, configuration)
        return if format.nil?

        configuration.mime_type_for(format) ||
          TYPES.fetch(format) { raise Hanami::Controller::UnknownFormatError.new(format) }
      end

      # Transforms MIME Types to symbol
      # Used for setting the format of the response
      #
      # @see Hanami::Action::Mime#finish
      # @example
      #   detect_format("text/html; charset=utf-8", configuration)  #=> :html
      #
      # @return [Symbol, nil]
      #
      # @since 2.0.0
      # @api private
      def self.detect_format(content_type, config)
        return if content_type.nil?

        ct = content_type.split(";").first
        config.format_for(ct) || format_for(ct)
      end

      # @since 2.0.0
      # @api private
      def self.format_for(content_type)
        TYPES.key(content_type)
      end

      # Transforms symbols to MIME Types
      # @example
      #   restrict_mime_types(config, [:json])  #=> ["application/json"]
      #
      # @return [Array<String>, nil]
      #
      # @raise [Hanami::Controller::UnknownFormatError] if the format is invalid
      #
      # @since 2.0.0
      # @api private
      def self.restrict_mime_types(config)
        return if config.accepted_formats.empty?

        mime_types = config.accepted_formats.map do |format|
          format_to_mime_type(format, config)
        end

        accepted_mime_types = mime_types & config.mime_types

        return if accepted_mime_types.empty?

        accepted_mime_types
      end

      # Use for checking the Content-Type header to make sure is valid based
      # on the accepted_mime_types
      #
      # If no Content-Type is sent in the request it will check the default_request_format
      #
      # @return [TrueClass, FalseClass]
      #
      # @since 2.0.0
      # @api private
      def self.accepted_mime_type?(request, accepted_mime_types, configuration)
        mime_type = request.content_type ||
                    default_content_type(configuration) ||
                    Action::DEFAULT_CONTENT_TYPE

        accepted_mime_types.any? { |mt| ::Rack::Mime.match?(mt, mime_type) }
      end

      # Use for setting the content_type and charset if the response
      #
      # @see Hanami::Action::Mime#call
      #
      # @return [String]
      #
      # @since 2.0.0
      # @api private
      def self.calculate_content_type_with_charset(configuration, request, accepted_mime_types)
        charset      = self.charset(configuration.default_charset)
        content_type = self.content_type(configuration, request, accepted_mime_types)
        content_type_with_charset(content_type, charset)
      end

      # private

      # Patched version of <tt>Rack::Utils.best_q_match</tt>.
      #
      # @since 2.0.0
      # @api private
      #
      # @see http://www.rubydoc.info/gems/rack/Rack/Utils#best_q_match-class_method
      # @see https://github.com/rack/rack/pull/659
      # @see https://github.com/hanami/controller/issues/59
      # @see https://github.com/hanami/controller/issues/104
      # @see https://github.com/hanami/controller/issues/275
      def self.best_q_match(q_value_header, available_mimes = TYPES.values)
        ::Rack::Utils.q_values(q_value_header).each_with_index.map do |(req_mime, quality), index|
          match = available_mimes.find { |am| ::Rack::Mime.match?(am, req_mime) }
          next unless match

          RequestMimeWeight.new(req_mime, quality, index, match)
        end.compact.max&.format
      end

      # @since 1.0.1
      # @api private
      class RequestMimeWeight
        # @since 2.0.0
        # @api private
        MIME_SEPARATOR = "/"
        private_constant :MIME_SEPARATOR

        # @since 2.0.0
        # @api private
        MIME_WILDCARD = "*"
        private_constant :MIME_WILDCARD

        include Comparable

        # @since 1.0.1
        # @api private
        attr_reader :quality

        # @since 1.0.1
        # @api private
        attr_reader :index

        # @since 1.0.1
        # @api private
        attr_reader :mime

        # @since 1.0.1
        # @api private
        attr_reader :format

        # @since 1.0.1
        # @api private
        attr_reader :priority

        # @since 1.0.1
        # @api private
        def initialize(mime, quality, index, format = mime)
          @quality, @index, @format = quality, index, format
          calculate_priority(mime)
        end

        # @since 1.0.1
        # @api private
        def <=>(other)
          return priority <=> other.priority unless priority == other.priority

          other.index <=> index
        end

        private

        # @since 1.0.1
        # @api private
        def calculate_priority(mime)
          @priority ||= (mime.split(MIME_SEPARATOR, 2).count(MIME_WILDCARD) * -10) + quality
        end
      end
    end
  end
end
