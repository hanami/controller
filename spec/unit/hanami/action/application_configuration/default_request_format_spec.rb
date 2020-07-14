# frozen_string_literal: true

require "hanami/action/application_configuration"

RSpec.describe Hanami::Action::ApplicationConfiguration, "#default_request_format" do
  let(:configuration) { described_class.new }
  subject(:value) { configuration.default_request_format }

  it "returns the default" do
    is_expected.to eq :html
  end

  it "can be set" do
    configuration.default_request_format = :json
    is_expected.to eq :json
  end
end
