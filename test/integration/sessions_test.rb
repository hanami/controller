require 'test_helper'
require 'rack/test'
require 'hanami/router'

SessionRoutes = Hanami::Router.new do
  get    '/',       to: 'dashboard#index'
  post   '/login',  to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
end

SessionApplication = Rack::Builder.new do
  use Rack::Session::Cookie, secret: SecureRandom.hex(16)
  run SessionRoutes
end.to_app

StandaloneSessionApplication = Rack::Builder.new do
  use Rack::Session::Cookie, secret: SecureRandom.hex(16)
  run StandaloneSession.new
end

describe 'Sessions' do
  include Rack::Test::Methods

  def app
    SessionApplication
  end

  it "denies access if user isn't loggedin" do
    get '/'
    last_response.status.must_equal 401
  end

  it 'grant access after login' do
    post '/login'
    follow_redirect!
    last_response.status.must_equal 200
  end

  it 'logs out' do
    post '/login'
    follow_redirect!
    last_response.status.must_equal 200

    delete '/logout'

    get '/'
    last_response.status.must_equal 401
  end
end

describe 'Standalone Sessions' do
  include Rack::Test::Methods

  def app
    StandaloneSessionApplication
  end

  it 'sets the session value' do
    get '/'
    last_response.status.must_equal 200
    last_response.headers.fetch('Set-Cookie').must_match(/\Arack\.session/)
  end
end
