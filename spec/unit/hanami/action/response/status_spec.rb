RSpec.describe Hanami::Action::Response, "status codes" do
  subject(:response) {
    described_class.new(
      env: rack_env,
      request: request,
      config: Hanami::Action.config.dup
    )
  }
  let(:request) {
    Hanami::Action::Request.new(env: rack_env, params: {}, session_enabled: true)
  }
  let(:rack_env) {
    Rack::MockRequest.env_for("http://example.com/foo?q=bar")
  }

  it "accepts an integer status" do
    response.status = 422
    expect(response.status).to eql 422
  end

  it "translates a symbolic status to integer" do
    response.status = :unprocessable_entity
    expect(response.status).to eql 422
  end

  it "raises Hanami::Action::UnknownHttpStatusError if given an unrecognized integer status" do
    expect { response.status = 999 }.to raise_error(Hanami::Action::UnknownHttpStatusError)
  end

  it "raises Hanami::Action::UnknownHttpStatusError if given an unrecognized symbolic status" do
    expect { response.status = :invalid_status }.to raise_error(Hanami::Action::UnknownHttpStatusError)
  end
end
