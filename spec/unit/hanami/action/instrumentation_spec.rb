RSpec.describe Hanami::Action do
  let(:instrumentation) { Hanami::Controller::Instrumentation.new }

  let(:configuration) do
    Hanami::Controller::Configuration.new do |config|
      config.instrumentation = instrumentation
    end
  end

  let(:action) { CallAction.new(configuration: configuration) }

  it 'calls instrumentation object before handle action and after' do
    expect(instrumentation).to receive(:broadcast).with('hanami.action.start_processing', {})
    expect(instrumentation).to receive(:broadcast).with('hanami.action.processed', {})

    response = action.call({})

    expect(response.headers['X-Custom']).to eq('OK')
    expect(response.status).to              be(201)
    expect(response.body).to                eq(['Hi from TestAction!'])
  end
end
