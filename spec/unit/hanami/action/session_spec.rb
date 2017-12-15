RSpec.describe Hanami::Action do
  describe "#session" do
    it "captures session from Rack env" do
      action   = SessionAction.new(configuration: configuration)
      response = action.call("rack.session" => session = { "user_id" => "23" })

      expect(response.session).to eq(session)
    end

    it "returns empty hash when it is missing" do
      action   = SessionAction.new(configuration: configuration)
      response = action.call({})

      expect(response.session).to eq({})
    end

    it "exposes session" do
      action = SessionAction.new(configuration: configuration)
      response = action.call("rack.session" => session = { "foo" => "bar" })

      expect(response[:session]).to eq(session)
    end

    it "allows value access via symbols" do
      action   = SessionAction.new(configuration: configuration)
      response = action.call("rack.session" => { "foo" => "bar" })

      expect(response.session[:foo]).to eq("bar")
    end
  end

  describe "flash" do
    it "exposes flash" do
      action = FlashAction.new(configuration: configuration)
      response = action.call({})

      expect(response[:flash]).to be_kind_of(Hanami::Action::Flash)
      expect(response[:flash][:error]).to eq("ouch")
    end
  end
end
