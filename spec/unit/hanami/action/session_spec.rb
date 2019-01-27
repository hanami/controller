RSpec.describe Hanami::Action do
  describe "#session" do
    it "captures session from Rack env" do
      action   = SessionAction.new(configuration: configuration)
      response = action.call("rack.session" => { "user_id" => "23" })

      expect(response.session).to eq(user_id: "23")
    end

    it "returns empty hash when it is missing" do
      action   = SessionAction.new(configuration: configuration)
      response = action.call({})

      expect(response.session).to eq({})
    end

    it "exposes session" do
      action = SessionAction.new(configuration: configuration)
      response = action.call("rack.session" => { "foo" => "bar" })

      expect(response[:session]).to eq(foo: "bar")
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

    describe "#each" do
      it "iterates through data" do
        action = FlashAction.new(configuration: configuration)
        response = action.call({})

        result = []
        response.flash.each do |type, message|
          result << [type, message]
        end

        expect(result).to eq([[:error, "ouch"]])
      end
    end

    describe "#map" do
      it "iterates through data" do
        action = FlashAction.new(configuration: configuration)
        response = action.call({})

        result = response.flash.map do |type, message|
          [type, message]
        end

        expect(result).to eq([[:error, "ouch"]])
      end
    end
  end
end
