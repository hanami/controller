RSpec.describe Hanami::Action::Mime do
  it 'exposes content_type' do
    action = CallAction.new
    action.call({})
    expect(action.content_type).to eq('application/octet-stream')
  end
end
