# frozen_string_literal: true

require "dry/configurable"
require "hanami/utils/kernel"
require "pathname"
require_relative "mime"

module Hanami
  class Action
    class Configuration
      include Dry::Configurable

      # FIXME: API docs
      def initialize(*)
        super
        yield self if block_given?
      end

      # Specify how to handle an exception with an HTTP status
      #
      # Raised exceptions will return the configured HTTP status, only if
      #   `handled_exceptions` is set on `true`.
      #
      # @param exception [Hash] the exception class must be the key and the HTTP
      #   status the value
      #
      # @since 0.2.0
      #
      # @see Hanami::Controller#configure
      # @see Hanami::Action::Throwable
      #
      # @example
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configure do
      #     handle_exception ArgumentError => 400
      #   end
      setting :handled_exceptions, {}

      def handle_exception(exception)
        handled_exceptions.merge!(exception)
      end

      # Default Mime type to format mapping
      #
      # @since 0.2.0
      # @api private
      DEFAULT_FORMATS = {
        'application/octet-stream' => :all,
        '*/*'                      => :all,
        'text/html'                => :html
      }.freeze

      # TODO: docs
      setting :formats, DEFAULT_FORMATS.dup

      # Register a format
      #
      # @param hash [Hash] the symbol format must be the key and the mime type
      #   string must be the value of the hash
      #
      # @since 0.2.0
      #
      # @see Hanami::Action::Mime
      def format(hash)
        symbol, mime_type = *Utils::Kernel.Array(hash)
        formats[Utils::Kernel.String(mime_type)] = Utils::Kernel.Symbol(symbol)
      end

      # Returns a format for the given mime type
      #
      # @param mime_type [#to_s,#to_str] A mime type
      #
      # @return [Symbol,nil] the corresponding format, if present
      #
      # @see Hanami::Controller::Configuration#format
      #
      # @since 0.2.0
      # @api private
      def format_for(mime_type)
        formats[mime_type]
      end

      # Return the configured format's MIME types
      #
      # @since 0.8.0
      # @api private
      #
      # @see Hanami::Controller::Configuration#format
      def mime_types
        # FIXME: this isn't efficient. speed it up!
        ((formats.keys - DEFAULT_FORMATS.keys) +
          Hanami::Action::Mime::TYPES.values).freeze
      end

      # Returns a mime type for the given format
      #
      # @param format [#to_sym] a format
      #
      # @return [String,nil] the corresponding mime type, if present
      #
      # @since 0.2.0
      # @api private
      def mime_type_for(format)
        formats.key(format)
      end

      # Set a format as default fallback for all the requests without a strict
      # requirement for the mime type.
      #
      # The given format must be coercible to a symbol, and be a valid mime type
      # alias. If it isn't, at the runtime the framework will raise a
      # `Hanami::Controller::UnknownFormatError`.
      #
      # By default this value is nil.
      #
      # @since 0.5.0
      #
      # @see Hanami::Action::Mime
      #
      # FIXME: new API docs
      setting :default_request_format do |value|
        Utils::Kernel.Symbol(value) unless value.nil?
      end

      # Set a format to be used for all responses regardless of the request type.
      #
      # The given format must be coercible to a symbol, and be a valid mime type
      # alias. If it isn't, at the runtime the framework will raise a
      # `Hanami::Controller::UnknownFormatError`.
      #
      # By default this value is nil.
      #
      # @since 0.5.0
      #
      # @see Hanami::Action::Mime
      #
      # FIXME: new API docs
      setting :default_response_format do |format|
        Utils::Kernel.Symbol(format) unless format.nil?
      end

      # Set a charset as default fallback for all the requests without a strict
      # requirement for the charset.
      #
      # By default this value is nil.
      #
      # @since 0.3.0
      #
      # @see Hanami::Action::Mime
      #
      # FIXME: new API docs
      setting :default_charset

      # Set default headers for all responses
      #
      # By default this value is an empty hash.
      #
      # @since 0.4.0
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configuration.default_headers # => {}
      #
      # @example Setting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller::Configuration.new do |config|
      #     config.default_headers = {
      #       'X-Frame-Options' => 'DENY'
      #     }
      #   end
      setting :default_headers, {} do |header_options|
        header_options.compact
      end

      # Set default cookies options for all responses
      #
      # By default this value is an empty hash.
      #
      # @since 0.4.0
      #
      # @example Getting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller.configuration.cookies # => {}
      #
      # @example Setting the value
      #   require 'hanami/controller'
      #
      #   Hanami::Controller::Configuration.new do |config|
      #     config.cookies = {
      #       domain: 'hanamirb.org',
      #       path: '/controller',
      #       secure: true,
      #       httponly: true
      #     }
      #   end
      setting :cookies, {} do |cookie_options|
        cookie_options.compact
      end

      # @api private
      # @since 1.0.0
      setting :root_directory, Dir.pwd do |dir|
        Pathname(dir).realpath
      end

      # Default public directory
      #
      # It serves as base root for file downloads
      #
      # @since 1.0.0
      # @api private
      DEFAULT_PUBLIC_DIRECTORY = 'public'.freeze

      # FIXME: API docs
      setting :public_directory, DEFAULT_PUBLIC_DIRECTORY

      def public_directory
        # NOTE: This must be a string, for Rack compatibility
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
