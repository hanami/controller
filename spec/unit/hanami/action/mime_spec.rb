# frozen_string_literal: true

RSpec.describe Hanami::Action do
  describe "#content_type" do
    it "exposes MIME type" do
      action = CallAction.new
      action.call({})
      expect(action.content_type).to eq("application/octet-stream")
    end
  end
end
