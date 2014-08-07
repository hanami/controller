require 'test_helper'
require 'lotus/router'
require 'lotus/action/cache'

CacheControlRoutes = Lotus::Router.new do
  get '/default',              to: 'cache_control#default'
  get '/overriding',           to: 'cache_control#overriding'
  get '/symbol',               to: 'cache_control#symbol'
  get '/symbols',              to: 'cache_control#symbols'
  get '/hash',                 to: 'cache_control#hash'
  get '/private-and-public',   to: 'cache_control#private_public'
end

ExpiresRoutes = Lotus::Router.new do
  get '/default',              to: 'expires#default'
  get '/overriding',           to: 'expires#overriding'
  get '/symbol',               to: 'expires#symbol'
  get '/symbols',              to: 'expires#symbols'
  get '/hash',                 to: 'expires#hash'
end

ConditionalGetRoutes = Lotus::Router.new do
  get '/etag',               to: 'conditional_get#etag'
  get '/last-modified',      to: 'conditional_get#last_modified'
  get '/etag-last-modified', to: 'conditional_get#etag_last_modified'
end

class CacheControlController
  include Lotus::Controller

  action 'Default' do
    include Lotus::Action::Cache

    cache_control :public, max_age: 600

    def call(params)
    end
  end

  action 'Overriding' do
    include Lotus::Action::Cache

    cache_control :public, max_age: 600

    def call(params)
      cache_control :private
    end
  end

  action 'Symbol' do
    include Lotus::Action::Cache

    def call(params)
      cache_control :private
    end
  end

  action 'Symbols' do
    include Lotus::Action::Cache

    def call(params)
      cache_control :private, :no_cache, :no_store
    end
  end

  action 'Hash' do
    include Lotus::Action::Cache

    def call(params)
      cache_control :public, :no_store, max_age: 900, s_maxage: 86400, min_fresh: 500, max_stale: 700
    end
  end

  action 'PrivatePublic' do
    include Lotus::Action::Cache

    def call(params)
      cache_control :private, :public
    end
  end
end

class ExpiresController
  include Lotus::Controller

  action 'Default' do
    include Lotus::Action::Cache

    expires 900, :public, :no_cache

    def call(params)
    end
  end

  action 'Overriding' do
    include Lotus::Action::Cache

    expires 900, :public, :no_cache

    def call(params)
      expires 600, :private
    end
  end

  action 'Symbol' do
    include Lotus::Action::Cache

    def call(params)
      expires 900, :private
    end
  end

  action 'Symbols' do
    include Lotus::Action::Cache

    def call(params)
      expires 900, :private, :no_cache, :no_store
    end
  end

  action 'Hash' do
    include Lotus::Action::Cache

    def call(params)
      expires 900, :public, :no_store, s_maxage: 86400, min_fresh: 500, max_stale: 700
    end
  end
end

class ConditionalGetController
  include Lotus::Controller

  action 'Etag' do
    include Lotus::Action::Cache

    def call(params)
      fresh etag: 'updated'
    end
  end

  action 'LastModified' do
    include Lotus::Action::Cache

    def call(params)
      fresh last_modified: Time.now
    end
  end

  action 'EtagLastModified' do
    include Lotus::Action::Cache

    def call(params)
      fresh etag: 'updated', last_modified: Time.now
    end
  end
end

describe 'Cache control' do
  before do
    @app = Rack::MockRequest.new(CacheControlRoutes)
  end

  describe 'default cache control' do
    it 'returns default Cache-Control headers' do
      response = @app.get('/default')
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(public max-age=600)
    end

    describe 'but some action overrides it' do
      it 'returns more specific Cache-Control headers' do
        response = @app.get('/overriding')
        response.headers.fetch('Cache-Control').split(', ').must_equal %w(private)
      end
    end
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
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(public no-store max-age=900 s-maxage=86400 min-fresh=500 max-stale=700)
    end
  end

  describe "private and public directives" do
    it "ignores public directive" do
      response = @app.get('/private-and-public')
      response.headers.fetch('Cache-Control').must_equal('private')
    end
  end
end

describe 'Expires' do
  before do
    @app = Rack::MockRequest.new(ExpiresRoutes)
  end

  describe 'default cache control' do
    it 'returns default Cache-Control headers' do
      response = @app.get('/default')
      response.headers.fetch('Expires').must_equal (Time.now + 900).httpdate
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(public no-cache max-age=900)
    end

    describe 'but some action overrides it' do
      it 'returns more specific Cache-Control headers' do
        response = @app.get('/overriding')
        response.headers.fetch('Expires').must_equal (Time.now + 600).httpdate
        response.headers.fetch('Cache-Control').split(', ').must_equal %w(private max-age=600)
      end
    end
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
      response.headers.fetch('Cache-Control').split(', ').must_equal %w(public no-store s-maxage=86400 min-fresh=500 max-stale=700 max-age=900)
    end
  end
end

describe 'Fresh' do
  before do
    @app = Rack::MockRequest.new(ConditionalGetRoutes)
  end

  describe 'etag' do
    describe 'when etag matches HTTP_IF_NONE_MATCH header' do
      it 'halts 304 not modified' do
        response = @app.get('/etag', {'HTTP_IF_NONE_MATCH' => 'updated'})
        response.status.must_equal 304
      end

      it 'keeps the same etag header' do
        response = @app.get('/etag', {'HTTP_IF_NONE_MATCH' => 'outdated'})
        response.headers.fetch('ETag').must_equal 'updated'
      end
    end

    describe 'when etag does not match HTTP_IF_NONE_MATCH header' do
      it 'completes request' do
        response = @app.get('/etag', {'HTTP_IF_NONE_MATCH' => 'outdated'})
        response.status.must_equal 200
      end

      it 'returns etag header' do
        response = @app.get('/etag', {'HTTP_IF_NONE_MATCH' => 'outdated'})
        response.headers.fetch('ETag').must_equal 'updated'
      end
    end
  end

  describe 'last_modified' do
    describe 'when last modified is less than or equal to HTTP_IF_MODIFIED_SINCE header' do
      before { @modified_since = Time.new(2014, 1, 8, 0, 0, 0) }

      it 'halts 304 not modified' do
        Time.stub(:now, @modified_since) do
          response = @app.get('/last-modified', {'HTTP_IF_MODIFIED_SINCE' => @modified_since.httpdate})
          response.status.must_equal 304
        end
      end

      it 'keeps the same IfModifiedSince header' do
        Time.stub(:now, @modified_since) do
          response = @app.get('/last-modified', {'HTTP_IF_MODIFIED_SINCE' => @modified_since.httpdate})
          response.headers.fetch('Last-Modified').must_equal @modified_since.httpdate
        end
      end
    end

    describe 'when last modified is bigger than HTTP_IF_MODIFIED_SINCE header' do
      before do
        @modified_since = Time.new(2014, 1, 8, 0, 0, 0)
        @last_modified  = Time.new(2014, 2, 8, 0, 0, 0)
      end

      it 'completes request' do
        Time.stub(:now, @last_modified) do
          response = @app.get('/last-modified', {'HTTP_IF_MODIFIED_SINCE' => @modified_since.httpdate})
          response.status.must_equal 200
        end
      end

      it 'returns etag header' do
        Time.stub(:now, @last_modified) do
          response = @app.get('/last-modified', {'HTTP_IF_MODIFIED_SINCE' => @modified_since.httpdate})
          response.headers.fetch('Last-Modified').must_equal @last_modified.httpdate
        end
      end
    end
  end
end
