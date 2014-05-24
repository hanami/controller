require 'test_helper'
require 'rack/test'
require 'lotus/router'

FlashRoutes = Lotus::Router.new do
  post   '/setflash',       to: 'flash#set'
  get    '/getflash',       to: 'flash#get'
end

FlashApplication = Rack::Builder.new do
  use Rack::Session::Cookie, secret: SecureRandom.hex(16)
  run FlashRoutes
end.to_app

describe "the flash" do
  include Rack::Test::Methods

  def app
    FlashApplication
  end

  it 'sets and gets items in the flash' do
    post '/setflash'

    get '/getflash'
    last_response.body.must_equal "Thanks for signing up!"
    get '/getflash'
    last_response.body.must_equal ""
  end
end
