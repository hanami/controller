require 'lotus/action/cache/directives'

module Lotus
  module Action
    module Cache

      # Module with Cache-Control logic
      #
      # @since x.x.x
      # @api private
      module CacheControl

        # The HTTP header for Cache-Control
        #
        # @since x.x.x
        # @api private
        HEADER = 'Cache-Control'.freeze

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def cache_control(*values)
            @cache_control_directives ||= Directives.new(*values)
          end

          def cache_control_directives
            @cache_control_directives || Object.new.tap do |null_object|
              def null_object.headers
                Hash.new
              end
            end
          end
        end

        # Finalize the response including default cache headers into the response
        #
        # @since x.x.x
        # @api private
        #
        # @see Lotus::Action#finish
        def finish
          super
          headers.merge!(self.class.cache_control_directives.headers) unless headers.include? HEADER
        end

        # Class which stores CacheControl values
        #
        # @since x.x.x
        #
        # @api private
        #
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
