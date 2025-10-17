# frozen_string_literal: true

require "hanami/utils/kernel"
require "dry/core"

module Hanami
  class Action
    class Config
      # Action format configuration.
      #
      # @since 2.0.0
      # @api private
      class Formats
        include Dry.Equalizer(:accepted, :mapping)

        # @since 2.0.0
        # @api private
        attr_reader :mapping

        # The array of formats to accept requests by.
        #
        # @example
        #   config.formats.accepted = [:html, :json]
        #   config.formats.accepted # => [:html, :json]
        #
        # @since 2.0.0
        # @api public
        attr_reader :accepted

        # @see #accepted
        #
        # @since 2.0.0
        # @api public
        def values
          msg = <<~TEXT
            Hanami::Action `config.formats.values` is deprecated and will be removed in Hanami 2.4.

            Please use `config.formats.accepted` instead.

            See https://guides.hanamirb.org/v2.3/actions/formats-and-mime-types/ for details.
          TEXT
          warn(msg, category: :deprecated)

          accepted
        end

        # Returns the default format name.
        #
        # When a request is received that cannot
        #
        # @return [Symbol, nil] the default format name, if any
        #
        # @example
        #   @config.formats.default # => :json
        #
        # @since 2.0.0
        # @api public
        attr_reader :default

        # @since 2.0.0
        # @api private
        def initialize(accepted: [], default: nil, mapping: {})
          @accepted = accepted
          @default = default
          @mapping = mapping
        end

        # @since 2.0.0
        # @api private
        private def initialize_copy(original) # rubocop:disable Style/AccessModifierDeclarations
          super
          @accepted = original.accepted.dup
          @default = original.default
          @mapping = original.mapping.dup
        end

        # !@attribute [w] accepted
        #   @since 2.3.0
        #   @api public
        def accepted=(formats)
          @accepted = formats.map { |f| Hanami::Utils::Kernel.Symbol(f) }
        end

        # !@attribute [w] values
        #   @since 2.0.0
        #   @api public
        alias_method :values=, :accepted=

        # @since 2.3.0
        def accept(*formats)
          self.default = formats.first if default.nil?
          self.accepted = accepted | formats
        end

        # @api private
        def accepted_formats(standard_formats = {})
          accepted.to_h { |format|
            [
              format,
              mapping.fetch(format) { standard_formats[format] }
            ]
          }
        end

        # @since 2.3.0
        def default=(format)
          @default = format.to_sym
        end

        # Registers a format and its associated media types.
        #
        # @param format [Symbol] the format name
        # @param media_type [String] the format's media type
        # @param content_types [Array<String>] the acceptable content types for the format
        #
        # @example
        #   config.formats.register(:scim, media_type: "application/json+scim")
        #   config.formats.register(
        #     :jsonapi,
        #     media_type: "application/vnd.api+json",
        #     content_types: ["application/vnd.api+json", "application/json"]
        #   )
        #
        # @return [self]
        #
        # @since 2.3.0
        # @api public
        def register(format, media_type, accept_types: [media_type], content_types: [media_type])
          mapping[format] = Mime::Format.new(
            name: format.to_sym,
            media_type: media_type,
            accept_types: accept_types,
            content_types: content_types
          )

          self
        end

        # @overload add(format)
        #   Adds and enables a format.
        #
        #   @param format [Symbol]
        #
        #   @example
        #     config.formats.add(:json)
        #
        # @overload add(format, mime_type)
        #   Adds a custom format to MIME type mapping and enables the format.
        #   Adds a format mapping to a single MIME type.
        #
        #   @param format [Symbol]
        #   @param mime_type [String]
        #
        #   @example
        #     config.formats.add(:json, "application/json")
        #
        # @overload add(format, mime_types)
        #   Adds a format mapping to multiple MIME types.
        #
        #   @param format [Symbol]
        #   @param mime_types [Array<String>]
        #
        #   @example
        #     config.formats.add(:json, ["application/json+scim"])
        #
        # @return [self]
        #
        # @since 2.0.0
        # @api public
        def add(format, mime_types)
          msg = <<~TEXT
            Hanami::Action `config.formats.add` is deprecated and will be removed in Hanami 2.4.

            Please use `config.formats.register` instead.

            See https://guides.hanamirb.org/v2.3/actions/formats-and-mime-types/ for details.
          TEXT
          warn(msg, category: :deprecated)

          mime_type = Array(mime_types).first

          # The old behaviour would have subsequent mime types _replacing_ previous ones
          mapping.reject! { |_, format| format.media_type == mime_type }

          register(format, media_type: Array(mime_types).first)

          accept(format) unless @accepted.include?(format)

          self
        end

        # @since 2.0.0
        # @api private
        def empty?
          accepted.empty?
        end

        # @since 2.0.0
        # @api private
        def any?
          @accepted.any?
        end

        # @since 2.0.0
        # @api private
        def map(&blk)
          @accepted.map(&blk)
        end

        # Clears any previously added mappings and format values.
        #
        # @return [self]
        #
        # @since 2.0.0
        # @api public
        def clear
          @accepted = []
          @default = nil
          @mapping = {}

          self
        end

        # Returns an array of all accepted media types.
        #
        # @since 2.3.0
        # @api public
        def accept_types
          accepted.map { |format| mapping[format]&.accept_types }.flatten(1).compact
        end

        # Retrieve the format name associated with the given media type
        #
        # @param media_type [String] the media Type
        #
        # @return [Symbol,NilClass] the associated format name, if any
        #
        # @example
        #   @config.formats.format_for("application/json") # => :json
        #
        # @see #mime_type_for
        #
        # @since 2.0.0
        # @api public
        def format_for(media_type)
          mapping.values.reverse.find { |format| format.media_type == media_type }&.name
        end

        # Returns the media type associated with the given format.
        #
        # @param format [Symbol] the format name
        #
        # @return [String, nil] the associated media type, if any
        #
        # @example
        #   @config.formats.media_type_for(:json) # => "application/json"
        #
        # @see #format_for
        #
        # @since 2.3.0
        # @api public
        def media_type_for(format)
          mapping[format]&.media_type
        end

        # @api private
        def accept_types_for(format)
          mapping[format]&.accept_types || []
        end

        # @api private
        def content_types_for(format)
          mapping[format]&.content_types || []
        end

        # @see #media_type_for
        # @since 2.0.0
        # @api public
        alias_method :mime_type_for, :media_type_for

        # @see #media_type_for
        # @since 2.0.0
        # @api public
        alias_method :mime_types_for, :accept_types_for
      end
    end
  end
end
