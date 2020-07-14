# frozen_string_literal: true

require "hanami/action/application_configuration"

RSpec.describe Hanami::Action::ApplicationConfiguration, "#view_context_identifier" do
  let(:configuration) { described_class.new }
  subject(:value) { configuration.view_context_identifier }

  it "returns 'view.context' by default" do
    is_expected.to eq "view.context"
  end

  it "can be set" do
    configuration.view_context_identifier = "view.another_context"
    is_expected.to eq "view.another_context"
  end
end
