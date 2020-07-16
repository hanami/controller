require "hanami/action/application_configuration"
require "hanami/action/configuration"

RSpec.describe Hanami::Action::ApplicationConfiguration do
  subject(:configuration) { described_class.new }

  describe "#settings" do
    it "returns a set of available settings" do
      expect(configuration.settings).to be_a(Set)
      expect(configuration.settings).to include(:view_context_identifier, :handled_exceptions)
    end

    it "includes all action settings" do
      expect(configuration.settings).to include(Hanami::Action::Configuration.settings)
    end
  end
end
