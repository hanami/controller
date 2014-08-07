module Lotus
  module Action
    module Cache

      # Cache-Control directives which have values
      #
      # @since x.x.x
      # @api private
      VALUE_DIRECTIVES      = %i(max_age s_maxage min_fresh max_stale).freeze

      # Cache-Control directives which are implicitly true
      #
      # @since x.x.x
      # @api private
      NON_VALUE_DIRECTIVES  = %i(public private no_cache no_store no_transform must_revalidate proxy_revalidate).freeze

      # Class representing value directives
      #
      # ex: max-age=600
      #
      # @since x.x.x
      #
      # @api private
      #
      class ValueDirective
        attr_reader :name

        def initialize(name, value)
          @name, @value = name, value
        end

        def to_str
          "#{@name.to_s.tr('_', '-')}=#{@value.to_i}"
        end

        def valid?
          VALUE_DIRECTIVES.include? @name
        end
      end

      # Class representing non value directives
      #
      # ex: no-cache
      #
      # @since x.x.x
      #
      # @api private
      #
      class NonValueDirective
        attr_reader :name

        def initialize(name)
          @name = name
        end

        def to_str
          @name.to_s.tr('_', '-')
        end

        def valid?
          NON_VALUE_DIRECTIVES.include? @name
        end
      end

      # Collection of value and non value directives
      #
      # @since x.x.x
      #
      # @api private
      #
      class Directives
        include Enumerable

        def initialize(*values)
          @directives = []
          values.each do |directive_key|
            if directive_key.kind_of? Hash
              directive_key.each { |name, value| self.<< ValueDirective.new(name, value) }
            else
              self.<< NonValueDirective.new(directive_key)
            end
          end
        end

        def each
          @directives.each { |d| yield d }
        end

        def <<(directive)
          @directives << directive if directive.valid?
        end

        def values
          @directives.delete_if do |directive|
            directive.name == :public && @directives.map(&:name).include?(:private)
          end
        end

        def join(separator)
          values.join(separator)
        end
      end
    end
  end
end
