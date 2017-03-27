RSpec.describe Hanami::Controller::Error do
  it 'inherits from ::StandardError' do
    expect(Hanami::Controller::Error.superclass).to eq(StandardError)
  end
end
