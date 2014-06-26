require 'test_helper'
require 'lotus/router'

CacheControlRoutes = Lotus::Router.new do
  get '/symbol',               to: 'cache_control#symbol'
  get '/symbols',              to: 'cache_control#symbols'
  get '/hash',                 to: 'cache_control#hash'
  get '/hash-containing-time', to: 'cache_control#hash_containing_time'
end

ExpiresRoutes = Lotus::Router.new do
  get '/symbol',               to: 'expires#symbol'
  get '/symbols',              to: 'expires#symbols'
  get '/hash',                 to: 'expires#hash'
  get '/hash-containing-time', to: 'expires#hash_containing_time'
end

class CacheControlController
  include Lotus::Controller
  action 'Symbol' do
    def call(params)
      cache_control :private
    end
  end
  action 'Symbols' do
    def call(params)
      cache_control :private, :no_cache, :no_store
    end
  end
  action 'Hash' do
    def call(params)
      cache_control :public, :no_store, max_age: 900, s_maxage: 86400
    end
  end
  action 'HashContainingTime' do
    def call(params)
      cache_control :public, :no_store, max_age: (Time.now + 900), s_maxage: (Time.now + 86400)
    end
  end
end

class ExpiresController
  include Lotus::Controller
  action 'Symbol' do
    def call(params)
      expires 900, :private
    end
  end
  action 'Symbols' do
    def call(params)
      expires 900, :private, :no_cache, :no_store
    end
  end
  action 'Hash' do
    def call(params)
      expires 900, :public, :no_store, s_maxage: 86400
    end
  end
  action 'HashContainingTime' do
    def call(params)
      expires (Time.now + 900), :public, :no_store, s_maxage: (Time.now + 86400)
    end
  end
end

describe 'Cache control' do
  before do
    @app = Rack::MockRequest.new(CacheControlRoutes)
  end
  it 'accepts a Symbol' do
    response = @app.get('/symbol')
    response.headers.fetch('Cache-Control').must_equal('private')
  end
  it 'accepts multiple Symbols' do
    response = @app.get('/symbols')
    response.headers.fetch('Cache-Control').split(', ').must_equal %w(private no-cache no-store)
  end
  it 'accepts a Hash' do
    Time.stub(:now, Time.now) do
      response = @app.get('/hash')
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(public no-store max-age=900 s-maxage=86400)
    end
  end
  it 'accepts a Hash containing Time objects' do
    Time.stub(:now, Time.now) do
      response = @app.get('/hash-containing-time')
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(public no-store max-age=900 s-maxage=86400)
    end
  end
end

describe 'Expires' do
  before do
    @app = Rack::MockRequest.new(ExpiresRoutes)
  end
  it 'accepts a Symbol' do
    Time.stub(:now, Time.now) do
      response = @app.get('/symbol')
      response.headers.fetch('Expires').must_equal (Time.now + 900).httpdate
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(private max-age=900)
    end
  end
  it 'accepts multiple Symbols' do
    Time.stub(:now, Time.now) do
      response = @app.get('/symbols')
      response.headers.fetch('Expires').must_equal (Time.now + 900).httpdate
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(private no-cache no-store max-age=900)
    end
  end
  it 'accepts a Hash' do
    Time.stub(:now, Time.now) do
      response = @app.get('/hash')
      response.headers.fetch('Expires').must_equal (Time.now + 900).httpdate
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(public no-store s-maxage=86400 max-age=900)
    end
  end
  it 'accepts a Hash containing Time objects' do
    Time.stub(:now, Time.now) do
      response = @app.get('/hash-containing-time')
      response.headers.fetch('Expires').must_equal (Time.now + 900).httpdate
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(public no-store s-maxage=86400 max-age=900)
    end
  end
end