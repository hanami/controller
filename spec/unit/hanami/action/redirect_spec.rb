# frozen_string_literal: true

RSpec.describe Hanami::Action do
  describe "#redirect" do
    it "redirects to the given path" do
      action   = RedirectAction.new
      response = action.call({})

      expect(response.status).to be(302)
      expected_headers =
        if Hanami::Router.rack_3?
          {"content-type" => "application/octet-stream; charset=utf-8", "location" => "/destination"}
        else
          {"Location" => "/destination", "Content-Type" => "application/octet-stream; charset=utf-8", "Content-Length" => "5"}
        end
      expect(response.headers).to eq(expected_headers)
    end

    it "redirects with custom status code" do
      action   = StatusRedirectAction.new
      response = action.call({})

      expect(response.status).to be(301)
    end

    # Bug
    # See: https://github.com/hanami/hanami/issues/196
    it "corces location to a ::String" do
      response = SafeStringRedirectAction.new.call({})
      expect(response.headers.fetch("Location").class).to eq(::String)
    end
  end
end
