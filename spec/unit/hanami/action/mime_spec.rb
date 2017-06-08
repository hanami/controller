RSpec.describe Hanami::Action do
  describe "#content_type" do
    it "exposes MIME type" do
      action = CallAction.new(configuration: configuration)
      action.call({})
      expect(action.content_type).to eq("application/octet-stream")
    end
  end
end
