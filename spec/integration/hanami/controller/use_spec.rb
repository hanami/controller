# frozen_string_literal: true

require "rack/test"

RSpec.describe "Rack middleware integration" do
  include Rack::Test::Methods

  def response
    last_response
  end

  context "when an action mounts a Rack middleware" do
    let(:app) { UseActionApplication }

    it "uses the specified Rack middleware" do
      router = Hanami::Router.new do
        get "/", to: "use_action#index"
        get "/show", to: "use_action#show"
        get "/edit", to: "use_action#edit"
      end

      UseActionApplication = Rack::Builder.new do
        run router
      end.to_app

      get "/"

      expect(response.status).to                        be(200)
      expect(response.headers.fetch("X-Middleware")).to eq("OK")
      expect(response.headers).to_not                   have_key("Y-Middleware")
      expect(response.body).to                          eq("Hello from UseAction::Index")

      get "/show"

      expect(response.status).to                        be(200)
      expect(response.headers.fetch("Y-Middleware")).to eq("OK")
      expect(response.headers).to_not                   have_key("X-Middleware")
      expect(response.body).to                          eq("Hello from UseAction::Show")

      get "/edit"

      expect(response.status).to                        be(200)
      expect(response.headers.fetch("Z-Middleware")).to eq("OK")
      expect(response.headers).to_not                   have_key("X-Middleware")
      expect(response.headers).to_not                   have_key("Y-Middleware")
      expect(response.body).to                          eq("Hello from UseAction::Edit")
    end
  end

  context "not an action doesn't mount a Rack middleware" do
    let(:app) { NoUseActionApplication }

    it "action doens't use a middleware" do
      router = Hanami::Router.new do
        get "/", to: "no_use_action#index"
      end

      NoUseActionApplication = Rack::Builder.new do
        run router
      end.to_app

      get "/"

      expect(response.status).to      be(200)
      expect(response.headers).to_not have_key("X-Middleware")
      expect(response.body).to        eq("Hello from NoUseAction::Index")
    end
  end
end
