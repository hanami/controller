RSpec.describe Hanami::Action::Rack do
  let(:action) { MethodInspectionAction.new(configuration: configuration) }

  %w(GET POST PATCH PUT DELETE TRACE OPTIONS).each do |verb|
    it "returns current request method (#{verb})" do
      env = Rack::MockRequest.env_for('/', method: verb)
      response = action.call(env)

      expect(response.body).to eq([verb])
    end
  end
end
