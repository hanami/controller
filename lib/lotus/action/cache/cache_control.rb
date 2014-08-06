module Lotus
  module Action
    module Cache

      require 'lotus/action/cache/directives'

      # Class which stores CacheControl values
      #
      # @since 0.2.1
      #
      # @api private
      #
      module CacheControl

        # The HTTP header for Cache-Control
        #
        # @since 0.2.1
        # @api private
        HEADER = 'Cache-Control'.freeze

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          attr_reader :cache_directives

          def cache_control(*values)
            @cache_directives ||= Directives.new(*values)
          end
        end

        # Finalize the response including default cache headers into the response
        #
        # @since 0.2.1
        # @api private
        #
        # @see Lotus::Action#finish
        def finish
          super
          if self.class.cache_directives
            headers.merge!(self.class.cache_directives.headers) unless headers.include? HEADER
          end
        end

        class Directives
          def initialize(*values)
            @directives = Lotus::Action::Cache::Directives.new(*values)
          end

          def headers
            if @directives.any?
              { HEADER => @directives.join(', ') }
            else
              {}
            end
          end
        end
      end
    end
  end
end
