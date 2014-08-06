module Lotus
  module Action
    module Cache

      require 'lotus/action/cache/cache_control'

      # Class which stores Expires values
      #
      # @since 0.2.1
      #
      # @api private
      #
      module Expires

        # The HTTP header for Expires
        #
        # @since 0.2.1
        # @api private
        HEADER = 'Expires'.freeze

        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          attr_reader :expires_directives

          def expires(amount, *values)
            @expires_directives ||= Directives.new(amount, *values)
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
          if self.class.expires_directives
            headers.merge!(self.class.expires_directives.headers) unless headers.include? HEADER
          end
        end

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
