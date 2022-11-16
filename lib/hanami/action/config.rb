# frozen_string_literal: true

require "dry/configurable"

module Hanami
  class Action
    # Config for `Hanami::Action` classes.
    #
    # @see Hanami::Action.config
    #
    # @api public
    # @since 2.0.0
    class Config < Dry::Configurable::Config
      # Default MIME type to format mapping
      #
      # @since 0.2.0
      # @api private
      DEFAULT_FORMAT_MAPPINGS = {
        "application/octet-stream" => :all,
        "*/*" => :all,
        "text/html" => :html
      }.freeze

      # Default public directory
      #
      # This serves as the root directory for file downloads
      #
      # @since 1.0.0
      #
      # @api private
      DEFAULT_PUBLIC_DIRECTORY = "public"

      # @!attribute [rw] handled_exceptions
      #
      #   Specifies how to handle exceptions with an HTTP status.
      #
      #   Raised exceptions will return the corresponding HTTP status.
      #
      #   @return [Hash{Exception=>Integer}] exception classes as keys and HTTP statuses as values
      #
      #   @example
      #     config.handled_exceptions = {ArgumentError => 400}
      #
      #   @since 0.2.0

      # Specifies how to handle exceptions with an HTTP status
      #
      # Raised exceptions will return the corresponding HTTP status
      #
      # The specified exceptions will be merged with any previously configured
      # exceptions
      #
      # @param exceptions [Hash{Exception=>Integer}] exception classes as keys
      #   and HTTP statuses as values
      #
      # @return [void]
      #
      # @example
      #   config.handle_exceptions(ArgumentError => 400}
      #
      # @see handled_exceptions
      #
      # @since 0.2.0
      def handle_exception(exceptions)
        self.handled_exceptions = handled_exceptions
          .merge(exceptions)
          .sort { |(ex1, _), (ex2, _)| ex1.ancestors.include?(ex2) ? -1 : 1 }
          .to_h
      end

      # @!attribute [rw] format_mappings
      #
      #   Specifies the MIME type to format mapping for the action.
      #
      #   @return [Hash{String=>Symbol}] MIME type strings as keys and format symbols as values
      #
      #   @see #add_format
      #   @see Hanami::Action::Mime
      #
      #   @example
      #     config.format_mappings = {"text/html" => :html}
      #
      #   @since 0.2.0

      # Registers a MIME type to format mapping
      #
      # @param hash [Hash{Symbol=>String}] format symbols as keys and the MIME
      #   type strings must as values
      #
      # @return [void]
      #
      # @see #format_mappings
      # @see Hanami::Action::Mime
      #
      # @example
      #   config.format html: "text/html"
      #
      # @since 0.2.0
      def add_format(hash)
        symbol, mime_type = *Utils::Kernel.Array(hash)
        format_mappings[Utils::Kernel.String(mime_type)] = Utils::Kernel.Symbol(symbol)
      end

      # Returns the configured format for the given MIME type
      #
      # @param mime_type [#to_s,#to_str] A mime type
      #
      # @return [Symbol,nil] the corresponding format, nil if not found
      #
      # @see #add_format
      #
      # @since 0.2.0
      # @api private
      def format_for(mime_type)
        format_mappings[mime_type]
      end

      # Returns the configured format's MIME types
      #
      # @return [Array<String>] the format's MIME types
      #
      # @see #format_mappings=
      # @see #format
      #
      # @since 0.8.0
      #
      # @api private
      def mime_types
        # FIXME: this isn't efficient. speed it up!
        ((format_mappings.keys - DEFAULT_FORMAT_MAPPINGS.keys) +
          Hanami::Action::Mime::TYPES.values).freeze
      end

      # Returns a MIME type for the given format
      #
      # @param format [#to_sym] a format
      #
      # @return [String,nil] the corresponding MIME type, if present
      #
      # @since 0.2.0
      # @api private
      def mime_type_for(format)
        format_mappings.key(format)
      end

      # TODO: document
      def format(*formats)
        self.formats = formats

        # TODO: update this
        self.accepted_formats = formats
      end

      def default_format
        formats.first
      end

      # @since 2.0.0
      # @api private
      def accepted_mime_types
        accepted_formats.any? ? Mime.restrict_mime_types(self) : mime_types
      end

      # @!attribute [rw] default_charset
      #
      #   Sets a charset (character set) as default fallback for all the requests
      #   without a strict requirement for the charset.
      #
      #   By default, this value is nil.
      #
      #   @return [String]
      #
      #   @see Hanami::Action::Mime
      #
      #   @since 0.3.0

      # @!attribute [rw] default_headers
      #
      #   Sets default headers for all responses.
      #
      #   By default, this is an empty hash.
      #
      #   @return [Hash{String=>String}] the headers
      #
      #   @example
      #     config.default_headers = {"X-Frame-Options" => "DENY"}
      #
      #   @see default_headers
      #
      #   @since 0.4.0

      # @!attribute [rw] cookies
      #
      #   Sets default cookie options for all responses.
      #
      #   By default this, is an empty hash.
      #
      #   @return [Hash{Symbol=>String}] the cookie options
      #
      #   @example
      #     config.cookies = {
      #       domain: "hanamirb.org",
      #       path: "/controller",
      #       secure: true,
      #       httponly: true
      #     }
      #
      #   @since 0.4.0

      # @!attribute [rw] root_directory
      #
      #   Sets the the for the public directory, which is used for file downloads.
      #   This must be an existent directory.
      #
      #   Defaults to the current working directory.
      #
      #   @return [String] the directory path
      #
      #   @api private
      #
      #   @since 1.0.0

      # @!attribute [rw] public_directory
      #
      # Sets the path to public directory. This directory is used for file downloads.
      #
      # This given directory will be appended onto the root directory.
      #
      # By default, the public directory is `"public"`.
      # @return [String] the public directory path
      #
      # @example
      #   config.public_directory = "public"
      #   config.public_directory # => "/path/to/root/public"
      #
      # @see root_directory
      #
      # @since 2.0.0
      def public_directory
        # This must be a string, for Rack compatibility
        root_directory.join(super).to_s
      end
    end
  end
end
