# frozen_string_literal: true

RSpec.describe Hanami::Action::Rack do
  let(:action) { MethodInspectionAction.new }

  %w[GET POST PATCH PUT DELETE TRACE OPTIONS].each do |verb|
    it "returns current request method (#{verb})" do
      env = Rack::MockRequest.env_for("/", method: verb)
      _, _, body = action.call(env)

      expect(body).to eq([verb])
    end
  end
end
