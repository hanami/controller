require 'rack/test'
require 'hanami/router'
require 'hanami'

RSpec.describe "HTTP sessions" do
  include Rack::Test::Methods

  let(:router) do
    Hanami::Router.new do
      get    '/',       to: Dashboard::Index.new
      post   '/login',  to: Sessions::Create.new
      delete '/logout', to: Sessions::Destroy.new
    end
  end

  let(:app) do
    r = router
    Rack::Builder.new do
      use Rack::Session::Cookie, secret: SecureRandom.hex(16)
      run r
    end.to_app
  end

  def response
    last_response
  end

  it "denies access if user isn't loggedin" do
    get "/"

    expect(response.status).to be(401)
  end

  it "grant access after login" do
    post "/login"
    follow_redirect!

    expect(response.status).to be(200)
    expect(response.body).to   eq("User ID from session: 23")
  end

  it "logs out" do
    post "/login"
    follow_redirect!

    expect(response.status).to be(200)

    delete "/logout"

    get "/"
    expect(response.status).to be(401)
  end
end

RSpec.describe "HTTP Standalone Sessions" do
  include Rack::Test::Methods

  let(:app) do
    configuration = Hanami::Action::Configuration.new
    Rack::Builder.new do
      use Rack::Session::Cookie, secret: SecureRandom.hex(16)
      run StandaloneSession.new
    end.to_app
  end

  def response
    last_response
  end

  it "sets the session value" do
    get "/"
    expect(response.status).to be(200)
    expect(response.headers.fetch("Set-Cookie")).to match(/\Arack\.session/)
  end
end

RSpec.describe "Application actions / HTTP sessions", :application_integration do
  describe "Outside Hanami app" do
    subject(:action_class) { Class.new(Hanami::Action) }

    before do
      allow(Hanami).to receive(:respond_to?).with(:application?) { nil }
    end

    it "does not have HTTP sessions enabled" do
      expect(action_class.ancestors).not_to include(Hanami::Action::Session)
    end
  end

  describe "Inside Hanami app" do
    before do
      application_class

      module Main
      end

      Hanami.application.register_slice :main, namespace: Main, root: "/path/to/app/slices/main"
      Hanami.init
    end

    subject(:action_class) {
      module Main
        class Action < Hanami::Action
        end
      end

      Main::Action
    }

    context "with HTTP sessions enabled" do
      subject(:application_class) {
        module TestApp
          class Application < Hanami::Application
            config.actions.sessions = :cookie, {secret: "abc123"}
          end
        end
      }

      it "has HTTP sessions enabled" do
        expect(action_class.ancestors).to include(Hanami::Action::Session)
      end
    end

    context "CSRF protection explicitly disabled" do
      subject(:application_class) {
        module TestApp
          class Application < Hanami::Application
            config.sessions = nil
          end
        end
      }

      it "does not have HTTP sessions enabled" do
        expect(action_class.ancestors).not_to include(Hanami::Action::Session)
      end
    end

    context "HTTP sessions not enabled" do
      subject(:application_class) {
        module TestApp
          class Application < Hanami::Application
          end
        end
      }

      it "does not have HTTP session enabled" do
        expect(action_class.ancestors).not_to include(Hanami::Action::Session)
      end
    end
  end
end
