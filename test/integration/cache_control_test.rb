require 'test_helper'
require 'lotus/router'

CacheControlRoutes = Lotus::Router.new do
  get '/cache_control/public',  to: 'cache_control#public'
  get '/expires/public',  to: 'expires#public'
end

class CacheControlController
  include Lotus::Controller
  action 'Public' do

    def call(params)
      cache_control :public
    end
  end
end

class ExpiresController
  include Lotus::Controller
  action 'Public' do

    def call(params)
      expires 900, :public
    end
  end
end

describe 'Cache control' do
  before do
    @app = Rack::MockRequest.new(CacheControlRoutes)
  end

  it 'returns public cache-control headers' do
    response = @app.get('/cache_control/public')
    response.headers['Cache-Control'].split(', ').must_include('public')
  end

  it 'returns public cache-control as well as expires headers' do
    response = @app.get('/expires/public')
    # Timecop
    response.headers['Expires'].must_be_kind_of String
    response.headers['Cache-Control'].split(', ').must_include('public')
  end
end