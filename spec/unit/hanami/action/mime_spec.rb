# frozen_string_literal: true

RSpec.describe Hanami::Action do
  describe "#content_type" do
    it "exposes MIME type" do
      action = CallAction.new
      response = action.call({})
      expect(response.headers["Content-Type"]).to eq("application/octet-stream; charset=utf-8")
    end
  end
end
