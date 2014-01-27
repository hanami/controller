require 'test_helper'
require 'rack/test'
require 'lotus/router'

SessionRoutes = Lotus::Router.new do
  get    '/',       to: 'dashboard#index'
  post   '/login',  to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy'
end

SessionApplication = Rack::Builder.new do
  use Rack::Session::Cookie, secret: SecureRandom.hex(16)
  run SessionRoutes
end.to_app

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
