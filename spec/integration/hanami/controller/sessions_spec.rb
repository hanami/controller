require 'rack/test'
require 'hanami/router'

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
      run StandaloneSession.new(configuration: configuration)
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
