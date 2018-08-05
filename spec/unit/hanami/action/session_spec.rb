# frozen_string_literal: true

RSpec.describe Hanami::Action do
  describe "#session" do
    it "captures session from Rack env" do
      action = SessionAction.new
      action.call("rack.session" => session = { "user_id" => "23" })

      expect(action.session).to eq(session)
    end

    it "returns empty hash when it is missing" do
      action = SessionAction.new
      action.call({})

      expect(action.session).to eq({})
    end

    it "exposes session" do
      action = SessionAction.new
      action.call("rack.session" => session = { "foo" => "bar" })

      expect(action.exposures[:session]).to eq(session)
    end

    it "allows value access via symbols" do
      action = SessionAction.new
      action.call("rack.session" => { "foo" => "bar" })

      expect(action.session[:foo]).to eq("bar")
    end
  end

  describe "flash" do
    it "exposes flash" do
      action = FlashAction.new
      action.call({})

      flash = action.exposures[:flash]

      expect(flash).to be_kind_of(Hanami::Action::Flash)
      expect(flash[:error]).to eq("ouch")
    end

    describe "#each" do
      it "iterates through data" do
        action = FlashAction.new
        action.call({})

        flash = action.exposures[:flash]
        result = []
        flash.each do |type, message|
          result << [type, message]
        end
        expect(result).to eq([[:error, "ouch"]])
      end
    end

    describe "#map" do
      it "iterates through data" do
        action = FlashAction.new
        action.call({})

        flash = action.exposures[:flash]
        result = flash.map do |type, message|
          [type, message]
        end
        expect(result).to eq([[:error, "ouch"]])
      end
    end
  end
end
