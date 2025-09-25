# frozen_string_literal: true

RSpec.describe Hanami::Action::Response, "session features" do
  subject(:response) {
    described_class.new(
      env: rack_env,
      request: request,
      config: Hanami::Action.config.dup,
      session_enabled: true
    )
  }
  let(:request) {
    Hanami::Action::Request.new(
      env: rack_env,
      params: {},
      session_enabled: true
    )
  }
  let(:rack_env) {
    Rack::MockRequest.env_for("http://example.com/foo?q=bar")
  }

  it "uses the request's session object" do
    expect(response.session).to eql request.session
  end

  it "uses the request's flash object" do
    expect(response.flash).to eql request.flash
  end
end
