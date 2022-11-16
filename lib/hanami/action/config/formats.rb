# frozen_string_literal: true

module Hanami
  class Action
    class Config
      class Formats
        # Default MIME type to format mapping
        #
        # @since 2.0.0
        # @api private
        DEFAULT_MAPPING = {
          "application/octet-stream" => :all,
          "*/*" => :all,
          "text/html" => :html
        }.freeze

        # @since 2.0.0
        # @api private
        attr_reader :values, :mapping

        # @since 2.0.0
        # @api private
        def initialize(values: [], mapping: DEFAULT_MAPPING.dup)
          @values = values
          @mapping = mapping
        end

        # @since 2.0.0
        # @api private
        def initialize_copy(original)
          super
          @values = original.values.dup
          @mapping = original.mapping.dup
        end

        # @since 2.0.0
        # @api private
        def mapping=(mappings)
          @mapping = {}

          mappings.each do |symbol, mime_type|
            add(symbol => mime_type)
          end
        end

        # @since 2.0.0
        # @api private
        def values=(*formats)
          @values = Utils::Kernel.Array(formats)
        end

        # @since 2.0.0
        # @api private
        def empty?
          @values.empty?
        end

        # @since 2.0.0
        # @api private
        def any?
          @values.any?
        end

        # @since 2.0.0
        # @api private
        def map(&blk)
          @values.map(&blk)
        end

        # Add a custom format
        #
        # @param mapping [Hash]
        #
        # @example
        #   config.formats.add(json: "application/scim+json")
        #
        # @since 2.0.0
        # @api public
        def add(mapping)
          symbol, mime_type = *Utils::Kernel.Array(mapping)
          @mapping[Utils::Kernel.String(mime_type)] = Utils::Kernel.Symbol(symbol)
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
        # @since 2.0.0
        # @api public
        #
        # @see #mime_type_for
        def format_for(mime_type)
          @mapping[mime_type]
        end

        # Retrieve the MIME Type associated with the given format name
        #
        # @param format [Symbol] the format name
        #
        # @return [String,NilClass] the associated MIME Type, if any
        #
        # @example
        #   @config.formats.mime_type_for(:json) # => "application/json"
        #
        # @since 2.0.0
        # @api public
        #
        # @see #format_for
        def mime_type_for(format)
          @mapping.key(format)
        end

        # Retrieve the supported MIME Types
        #
        # @return [Array<String>] the supported MIME Types
        #
        # @example
        #   @config.formats.mime_types # => ["text/html", "application/json"]
        #
        # @since 2.0.0
        # @api public
        def mime_types
          # FIXME: this isn't efficient. speed it up!
          ((@mapping.keys - DEFAULT_MAPPING.keys) +
            Hanami::Action::Mime::TYPES.values).freeze
        end

        # Returns the default format name
        #
        # @return [Symbol,NilClass] the default format name, if any
        #
        # @example
        #   @config.formats.default # => :json
        #
        # @since 2.0.0
        # @api public
        def default
          @values.first
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
