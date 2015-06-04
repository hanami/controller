require 'test_helper'

describe Lotus::Action::Rack do
  before do
    @action = MethodInspectionAction.new
  end

  ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'TRACE', 'OPTIONS'].each do |verb|
    it "returns current request method (#{ verb })" do
      env = Rack::MockRequest.env_for('/', method: verb)
      _, _, body = @action.call(env)

      body.must_equal [verb]
    end
  end
end
