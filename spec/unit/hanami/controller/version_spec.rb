# frozen_string_literal: true

RSpec.describe "Hanami::Controller::VERSION" do
  it "returns current version" do
    expect(Hanami::Controller::VERSION).to eq("2.2.0.beta1")
  end
end
