module RSpec
  module Support
    module Context
      def self.included(base)
        base.class_eval do
          let(:configuration) { Hanami::Action::Configuration.new }
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include(RSpec::Support::Context)
end
