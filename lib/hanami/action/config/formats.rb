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
        include Dry.Equalizer(:values, :mapping)

        # Default MIME type to format mapping
        #
        # @since 2.0.0
        # @api private
        DEFAULT_MAPPING = {
          "application/octet-stream" => :all,
          "*/*" => :all
        }.freeze

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
        def initialize(accepted: [], default: nil, mapping: DEFAULT_MAPPING.dup)
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

        # @since 2.3.0
        def default=(format)
          @default = Hanami::Utils::Kernel.Symbol(format)
        end

        # Registers a format and its associated MIME types.
        #
        # @param formats_to_mime_types [Hash{Symbol => String, Array<String>}]
        #
        # @example
        #   config.formats.register(json: "application/json")
        #   config.formats.register(json: ["application/json+scim", "application/json"])
        #
        # @return [self]
        #
        # @since 2.3.0
        # @api public
        def register(formats_to_mime_types)
          formats_to_mime_types.each do |format, mime_types|
            format = Hanami::Utils::Kernel.Symbol(format)

            Array(mime_types).each do |mime_type|
              @mapping[Hanami::Utils::Kernel.String(mime_type)] = format
            end
          end

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
        #     config.formats.add(:json, ["application/json+scim", "application/json"])
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

          register(format => mime_types)

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

        # @since 2.0.0
        # @api private
        def mapping=(mappings)
          @mapping = {}
          register(mappings)
        end

        # Clears any previously added mappings and format values.
        #
        # @return [self]
        #
        # @since 2.0.0
        # @api public
        def clear
          @mapping = DEFAULT_MAPPING.dup
          @accepted = []
          @default = nil

          self
        end

        # Retrieve the format name associated with the given MIME Type
        #
        # @param mime_type [String] the MIME Type
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
        def format_for(mime_type)
          @mapping[mime_type]
        end

        # Returns the primary MIME type associated with the given format.
        #
        # @param format [Symbol] the format name
        #
        # @return [String, nil] the associated MIME type, if any
        #
        # @example
        #   @config.formats.mime_type_for(:json) # => "application/json"
        #
        # @see #format_for
        #
        # @since 2.0.0
        # @api public
        def mime_type_for(format)
          @mapping.key(format)
        end

        # Returns an array of all MIME types associated with the given format.
        #
        # Returns an empty array if no such format is configured.
        #
        # @param format [Symbol] the format name
        #
        # @return [Array<String>] the associated MIME types
        #
        # @since 2.0.0
        # @api public
        def mime_types_for(format)
          @mapping.each_with_object([]) { |(mime_type, f), arr| arr << mime_type if format == f }
        end

        # @since 2.0.0
        # @api private
        def keys
          @mapping.keys
        end
      end
    end
  end
end
