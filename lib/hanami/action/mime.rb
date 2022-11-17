# frozen_string_literal: true

require "hanami/utils"
require "rack/utils"
require "rack/mime"
require_relative "errors"

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
      def self.content_type(config, request, accepted_mime_types)
        if request.accept_header?
          type = best_q_match(request.accept, accepted_mime_types)
          return type if type
        end

        default_response_type(config) || Action::DEFAULT_CONTENT_TYPE
      end

      # @since 2.0.0
      # @api private
      def self.charset(default_charset)
        default_charset || Action::DEFAULT_CHARSET
      end

      # @since 2.0.0
      # @api private
      def self.default_response_type(config)
        format_to_mime_type(config.default_format, config)
      end

      # @since 2.0.0
      # @api private
      def self.format_to_mime_type(format, config)
        return if format.nil?

        config.mime_type_for(format) ||
          TYPES.fetch(format) { raise Hanami::Action::UnknownFormatError.new(format) }
      end

      # Transforms MIME Types to symbol
      # Used for setting the format of the response
      #
      # @see Hanami::Action::Mime#finish
      # @example
      #   detect_format("text/html; charset=utf-8", config)  #=> :html
      #
      # @return [Symbol, nil]
      #
      # @since 2.0.0
      # @api private
      def self.detect_format(content_type, config)
        return if content_type.nil?

        ct = content_type.split(";").first
        config.formats.format_for(ct) || format_for(ct)
      end

      # @since 2.0.0
      # @api private
      def self.format_for(content_type)
        TYPES.key(content_type)
      end

      # @since 2.0.0
      # @api private
      def self.detect_format_and_content_type(value, config)
        case value
        when Symbol
          [value, format_to_mime_type(value, config)]
        when String
          [detect_format(value, config), value]
        else
          raise UnknownFormatError.new(value)
        end
      end

      # Transforms symbols to MIME Types
      # @example
      #   restrict_mime_types(config, [:json])  #=> ["application/json"]
      #
      # @return [Array<String>, nil]
      #
      # @raise [Hanami::Action::UnknownFormatError] if the format is invalid
      #
      # @since 2.0.0
      # @api private
      def self.restrict_mime_types(config)
        return if config.formats.empty?

        mime_types = config.formats.map do |format|
          format_to_mime_type(format, config)
        end

        accepted_mime_types = mime_types & config.mime_types

        return if accepted_mime_types.empty?

        accepted_mime_types
      end

      # Yields if an action is configured with `formats`, the request has an `Accept` header, an
      # none of the Accept types matches the accepted formats. The given block is expected to halt
      # the request handling.
      #
      # If any of these conditions are not met, then the request is acceptable and the method
      # returns without yielding.
      #
      # @see Action#enforce_accepted_mime_types
      # @see Config#formats
      #
      # @since 2.0.0
      # @api private
      def self.enforce_accept(request, config)
        return unless request.accept_header?

        accept_types = ::Rack::Utils.q_values(request.accept).map(&:first)
        return if accept_types.any? { |mime_type| accepted_mime_type?(mime_type, config) }

        yield
      end

      # Yields if an action is configured with `formats`, the request has a `Content-Type` header
      # (or a `default_requst_format` is configured), and the content type does not match the
      # accepted formats. The given block is expected to halt the request handling.
      #
      # If any of these conditions are not met, then the request is acceptable and the method
      # returns without yielding.
      #
      # @see Action#enforce_accepted_mime_types
      # @see Config#formats
      #
      # @since 2.0.0
      # @api private
      def self.enforce_content_type(request, config)
        content_type = request.content_type

        return if content_type.nil?

        return if accepted_mime_type?(content_type, config)

        yield
      end

      # @since 2.0.0
      # @api private
      def self.accepted_mime_type?(mime_type, config)
        config.accepted_mime_types.any? { |accepted_mime_type|
          ::Rack::Mime.match?(accepted_mime_type, mime_type)
        }
      end

      # Use for setting the content_type and charset if the response
      #
      # @return [String]
      #
      # @since 2.0.0
      # @api private
      def self.calculate_content_type_with_charset(config, request, accepted_mime_types)
        charset = self.charset(config.default_charset)
        content_type = self.content_type(config, request, accepted_mime_types)
        content_type_with_charset(content_type, charset)
      end

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
