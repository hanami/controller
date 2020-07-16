# frozen_string_literal: true

require "dry/configurable"
require "hanami/utils/kernel"
require "pathname"
require_relative "mime"

module Hanami
  class Action
    class Configuration
      include Dry::Configurable

      # Initialize the Configuration
      #
      # @yield [config] the configuration object
      #
      # @return [Configuration]
      #
      # @since 2.0.0
      # @api private
      def initialize(*)
        super
        yield self if block_given?
      end

      # Returns the list of available settings
      #
      # @return [Set]
      #
      # @since 2.0.0
      # @api private
      def settings
        self.class.settings
      end

      # @!method handled_exceptions=(exceptions)
      #
      #   Specifies how to handle exceptions with an HTTP status
      #
      #   Raised exceptions will return the corresponding HTTP status
      #
      #   @param exceptions [Hash{Exception=>Integer}] exception classes as
      #     keys and HTTP statuses as values
      #
      #   @return [void]
      #
      #   @since 0.2.0
      #
      #   @example
      #     configuration.handled_exceptions = {ArgumentError => 400}
      #
      # @!method handled_exceptions
      #
      #   Returns the configured handled exceptions
      #
      #   @return [Hash{Exception=>Integer}]
      #
      #   @see handled_exceptions=
      #
      #   @since 0.2.0
      setting :handled_exceptions, {}

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
        handled_exceptions.merge!(exceptions)
      end

      # Default MIME type to format mapping
      #
      # @since 0.2.0
      # @api private
      DEFAULT_FORMATS = {
        'application/octet-stream' => :all,
        '*/*'                      => :all,
        'text/html'                => :html
      }.freeze

      # @!method formats=(formats)
      #
      #   Specifies the MIME type to format mapping
      #
      #   @param formats [Hash{String=>Symbol}] MIME type strings as keys and
      #     format symbols as values
      #
      #   @return [void]
      #
      #   @since 0.2.0
      #
      #   @see format
      #   @see Hanami::Action::Mime
      #
      #   @example
      #     configuration.formats = {"text/html" => :html}
      #
      # @!method formats
      #
      #   Returns the configured MIME type to format mapping
      #
      #   @return [Symbol,nil] the corresponding format, if present
      #
      #   @see format
      #   @see formats=
      #
      #   @since 0.2.0
      setting :formats, DEFAULT_FORMATS.dup

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

      # @!method default_request_format=(format)
      #
      #   Sets a format as default fallback for all the requests without a strict
      #   requirement for the MIME type.
      #
      #   The given format must be coercible to a symbol, and be a valid MIME
      #   type alias. If it isn't, at runtime the framework will raise an
      #   `Hanami::Controller::UnknownFormatError`.
      #
      #   By default, this value is nil.
      #
      #   @param format [Symbol]
      #
      #   @return [void]
      #
      #   @since 0.5.0
      #
      #   @see Hanami::Action::Mime
      #
      # @!method default_request_format
      #
      #   Returns the configured default request format
      #
      #   @return [Symbol] format
      #
      #   @see default_request_format=
      #
      #   @since 0.5.0
      setting :default_request_format do |format|
        Utils::Kernel.Symbol(format) unless format.nil?
      end

      # @!method default_response_format=(format)
      #
      #   Sets a format to be used for all responses regardless of the request
      #   type.
      #
      #   The given format must be coercible to a symbol, and be a valid MIME
      #   type alias. If it isn't, at the runtime the framework will raise an
      #   `Hanami::Controller::UnknownFormatError`.
      #
      #   By default, this value is nil.
      #
      #   @param format [Symbol]
      #
      #   @return [void]
      #
      #   @since 0.5.0
      #
      #   @see Hanami::Action::Mime
      #
      # @!method default_response_format
      #
      #   Returns the configured default response format
      #
      #   @return [Symbol] format
      #
      #   @see default_request_format=
      #
      #   @since 0.5.0
      setting :default_response_format do |format|
        Utils::Kernel.Symbol(format) unless format.nil?
      end

      # @!method default_charset=(charset)
      #
      #   Sets a charset (character set) as default fallback for all the requests
      #   without a strict requirement for the charset.
      #
      #   By default, this value is nil.
      #
      #   @param charset [String]
      #
      #   @return [void]
      #
      #   @since 0.3.0
      #
      #   @see Hanami::Action::Mime
      #
      # @!method default_charset
      #
      #   Returns the configured default charset.
      #
      #   @return [String,nil] the charset, if present
      #
      #   @see default_charset=
      #
      #   @since 0.3.0
      setting :default_charset

      # @!method default_headers=(headers)
      #
      #   Sets default headers for all responses.
      #
      #   By default, this is an empty hash.
      #
      #   @param headers [Hash{String=>String}] the headers
      #
      #   @return [void]
      #
      #   @since 0.4.0
      #
      #   @see default_headers
      #
      #   @example
      #     configuration.default_headers = {'X-Frame-Options' => 'DENY'}
      #
      # @!method default_headers
      #
      #   Returns the configured headers
      #
      #   @return [Hash{String=>String}] the headers
      #
      #   @since 0.4.0
      #
      #   @see default_headers=
      setting :default_headers, {} do |headers|
        headers.compact
      end

      # @!method cookies=(cookie_options)
      #
      #   Sets default cookie options for all responses.
      #
      #   By default this, is an empty hash.
      #
      #   @param cookie_options [Hash{Symbol=>String}] the cookie options
      #
      #   @return [void]
      #
      #   @since 0.4.0
      #
      #   @example
      #     configuration.cookies = {
      #       domain: 'hanamirb.org',
      #       path: '/controller',
      #       secure: true,
      #       httponly: true
      #     }
      #
      # @!method cookies
      #
      #   Returns the configured cookie options
      #
      #   @return [Hash{Symbol=>String}]
      #
      #   @since 0.4.0
      #
      #   @see cookies=
      setting :cookies, {} do |cookie_options|
        cookie_options.compact
      end

      # @!method root_directory=(dir)
      #
      #   Sets the the for the public directory, which is used for file downloads.
      #   This must be an existent directory.
      #
      #   Defaults to the current working directory.
      #
      #   @param dir [String] the directory path
      #
      #   @return [void]
      #
      #   @since 1.0.0
      #
      #   @api private
      #
      # @!method root_directory
      #
      #   Returns the configured root directory
      #
      #   @return [String] the directory path
      #
      #   @see root_directory=
      #
      #   @since 1.0.0
      #
      #   @api private
      setting :root_directory, Dir.pwd do |dir|
        Pathname(dir).realpath
      end

      # Default public directory
      #
      # This serves as the root directory for file downloads
      #
      # @since 1.0.0
      #
      # @api private
      DEFAULT_PUBLIC_DIRECTORY = 'public'.freeze

      # @!method public_directory=(directory)
      #
      #   Sets the path to public directory. This directory is used for file downloads.
      #
      #   This given directory will be appended onto the root directory.
      #
      #   By default, the public directory is "public".
      #
      #   @param directory [String] the public directory path
      #
      #   @return [void]
      #
      #   @see root_directory
      #   @see public_directory
      setting :public_directory, DEFAULT_PUBLIC_DIRECTORY

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
      # @see public_directory=
      # @see root_directory=
      def public_directory
        # This must be a string, for Rack compatibility
        root_directory.join(super).to_s
      end

      private

      def method_missing(name, *args, &block)
        if config.respond_to?(name)
          config.public_send(name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(name, _incude_all = false)
        config.respond_to?(name) || super
      end
    end
  end
end
