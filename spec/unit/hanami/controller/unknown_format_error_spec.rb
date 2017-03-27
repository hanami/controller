RSpec.describe Hanami::Controller::UnknownFormatError do
  it 'inheriths from Hanami::Controller::Error' do
    expect(Hanami::Controller::UnknownFormatError.superclass).to eq(Hanami::Controller::Error)
  end
end
