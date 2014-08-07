require 'lotus/action/cache/cache_control'

module Lotus
  module Action
    module Cache

      # Module with Expires logic
      #
      # @since x.x.x
      # @api private
      module Expires

        # The HTTP header for Expires
        #
        # @since x.x.x
        # @api private
        HEADER = 'Expires'.freeze

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def expires(amount, *values)
            @expires_directives ||= Directives.new(amount, *values)
          end

          def expires_directives
            @expires_directives || Object.new.tap do |null_object|
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
          headers.merge!(self.class.expires_directives.headers) unless headers.include? HEADER
        end

        # Class which stores Expires directives
        #
        # @since x.x.x
        #
        # @api private
        #
        class Directives
          def initialize(amount, *values)
            @amount = amount
            @cache_control = Lotus::Action::Cache::CacheControl::Directives.new(*(values << { max_age: amount }))
          end

          def headers
            { HEADER => time.httpdate }.merge(@cache_control.headers)
          end

          private

          def time
            Time.now + @amount.to_i
          end
        end
      end
    end
  end
end
