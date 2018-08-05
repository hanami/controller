# frozen_string_literal: true

RSpec.describe Hanami::Action do
  describe ".after" do
    it "invokes the method(s) from the given symbol(s) after the action is run" do
      action = AfterMethodAction.new
      action.call({})

      expect(action.egg).to eq("gE!g")
      expect(action.logger.join(" ")).to eq("Mrs. Jane Dixit")
    end

    it "invokes the given block after the action is run" do
      action = AfterBlockAction.new
      action.call({})

      expect(action.egg).to eq("Coque".reverse)
    end

    it "inherits callbacks from superclass" do
      action = SubclassAfterMethodAction.new
      action.call({})

      expect(action.egg).to eq("gE!g".upcase)
    end

    it "can optionally have params in method signature" do
      action = ParamsAfterMethodAction.new
      action.call(question: "?")

      expect(action.egg).to eq("gE!g?")
    end

    it "yields params when the callback is a block" do
      action = YieldAfterBlockAction.new
      action.call("fortytwo" => "42")

      expect(action.meaning_of_life_params.to_h).to eq(fortytwo: "42")
    end

    describe "on error" do
      it "stops the callbacks execution and returns an HTTP 500 status" do
        action   = ErrorAfterMethodAction.new
        response = action.call({})

        expect(response[0]).to be(500)
        expect(action.egg).to  be(nil)
      end
    end

    describe "on handled error" do
      it "stops the callbacks execution and passes the control on exception handling" do
        action   = HandledErrorAfterMethodAction.new
        response = action.call({})

        expect(response[0]).to be(404)
        expect(action.egg).to  be(nil)
      end
    end
  end
end
