require "hanami/action/application_configuration"
require "hanami/action/configuration"

RSpec.describe Hanami::Action::ApplicationConfiguration do
  subject(:configuration) { described_class.new }

  it "configures base settings" do
    expect { configuration.default_request_format = :json }
      .to change { configuration.default_request_format }
      .to :json
  end

  it "configures base settings using custom methods" do
    configuration.formats = {}

    expect { configuration.format json: "application/json" }
      .to change { configuration.formats }
      .to("application/json" => :json)
  end

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
