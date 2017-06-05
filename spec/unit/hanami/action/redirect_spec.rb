RSpec.describe Hanami::Action do
  describe "#redirect" do
    it "redirects to the given path" do
      action   = RedirectAction.new
      response = action.call({})

      expect(response[0]).to be(302)
      expect(response[1]).to eq("Location" => "/destination", "Content-Type" => "application/octet-stream; charset=utf-8")
    end

    it "redirects with custom status code" do
      action   = StatusRedirectAction.new
      response = action.call({})

      expect(response[0]).to be(301)
    end

    # Bug
    # See: https://github.com/hanami/hanami/issues/196
    it "corces location to a ::String" do
      response = SafeStringRedirectAction.new.call({})
      expect(response[1]["Location"].class).to eq(::String)
    end
  end
end
