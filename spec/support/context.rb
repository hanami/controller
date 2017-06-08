module RSpec
  module Support
    module Context
      def self.included(base)
        base.class_eval do
          let(:configuration) do
            configuration = Hanami::Controller::Configuration.new do |config|
            end

            # Hanami::Controller.finalize(configuration)
          end
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include(RSpec::Support::Context)
end
