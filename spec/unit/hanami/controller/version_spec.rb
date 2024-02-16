# frozen_string_literal: true

RSpec.describe "Hanami::Controller::VERSION" do
  it "returns current version" do
    expect(Hanami::Controller::VERSION).to eq("2.1.0.rc3")
  end
end
