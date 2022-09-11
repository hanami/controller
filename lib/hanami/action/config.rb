# frozen_string_literal: true

require "dry/configurable"
require_relative "mime"

module Hanami
  class Action
    class Config < Dry::Configurable::Config
      # Default MIME type to format mapping
      #
      # @since 0.2.0
      # @api private
      DEFAULT_FORMATS = {
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
      # @since 0.2.0
      #
      # @see handled_exceptions=
      #
      # @example
      #   configuration.handle_exceptions(ArgumentError => 400}
      def handle_exception(exceptions)
        self.handled_exceptions = handled_exceptions
          .merge(exceptions)
          .sort { |(ex1, _), (ex2, _)| ex1.ancestors.include?(ex2) ? -1 : 1 }
          .to_h
      end

      # Registers a MIME type to format mapping
      #
      # @param hash [Hash{Symbol=>String}] format symbols as keys and the MIME
      #   type strings must as values
      #
      # @return [void]
      #
      # @since 0.2.0
      #
      # @see Hanami::Action::Mime
      #
      # @example configuration.format html: "text/html"
      def format(hash)
        symbol, mime_type = *Utils::Kernel.Array(hash)
        formats[Utils::Kernel.String(mime_type)] = Utils::Kernel.Symbol(symbol)
      end

      # Returns the configured format for the given MIME type
      #
      # @param mime_type [#to_s,#to_str] A mime type
      #
      # @return [Symbol,nil] the corresponding format, nil if not found
      #
      # @see format
      #
      # @since 0.2.0
      # @api private
      def format_for(mime_type)
        formats[mime_type]
      end

      # Returns the configured format's MIME types
      #
      # @return [Array<String>] the format's MIME types
      #
      # @see formats=
      # @see format
      #
      # @since 0.8.0
      #
      # @api private
      def mime_types
        # FIXME: this isn't efficient. speed it up!
        ((formats.keys - DEFAULT_FORMATS.keys) +
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
        formats.key(format)
      end

      # Returns the configured public directory, appended onto the root directory.
      #
      # @return [String] the fill directory path
      #
      # @example
      #   configuration.public_directory = "public"
      #
      #   configuration.public_directory
      #   # => "/path/to/root/public"
      #
      # @since 2.0.0
      #
      # @see public_directory=
      # @see root_directory=
      def public_directory
        # This must be a string, for Rack compatibility
        root_directory.join(super).to_s
      end
    end
  end
end
