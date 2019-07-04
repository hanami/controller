# frozen_string_literal: true

module RSpec
  module Support
    module Validations
      module Matcher
        def self.version?(version)
          return ::Hanami::Validations::VERSION =~ /\A#{version}/ if defined?(::Hanami::Validations::VERSION)

          version == 1
        end
      end

      def self.version?(version)
        Matcher.version?(version)
      end

      private

      def with_hanami_validations(version)
        yield if Matcher.version?(version)
      end
    end
  end
end

RSpec.configure do |config|
  config.include(RSpec::Support::Validations)
end
