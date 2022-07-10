RSpec.describe Hanami::Controller::Error do
  it "inherits from ::StandardError" do
    expect(described_class.superclass).to eq(StandardError)
  end
end
