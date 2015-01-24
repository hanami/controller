require 'test_helper'
require 'rack/test'

describe 'Rack middleware integration' do
  include Rack::Test::Methods

  def response
    last_response
  end

  describe '.use' do
    let(:app) { UseActionApplication }

    it 'uses the specified Rack middleware' do
      router = Lotus::Router.new do
        get '/', to: 'use_action#index'
        get '/show', to: 'use_action#show'
      end

      UseActionApplication = Rack::Builder.new do
        run router
      end.to_app

      get '/'

      response.status.must_equal 200
      response.headers.fetch('X-Middleware').must_equal 'OK'
      response.headers['Y-Middleware'].must_be_nil
      response.body.must_equal 'Hello from UseAction::Index'

      get '/show'

      response.status.must_equal 200
      response.headers.fetch('Y-Middleware').must_equal 'OK'
      response.headers['X-Middleware'].must_be_nil
      response.body.must_equal 'Hello from UseAction::Show'
    end
  end

  describe 'not using .use' do
    let(:app) { NoUseActionApplication }

    it "action doens't use a middleware" do
      router = Lotus::Router.new do
        get '/', to: 'no_use_action#index'
      end

      NoUseActionApplication = Rack::Builder.new do
        run router
      end.to_app

      get '/'

      response.status.must_equal 200
      response.headers['X-Middleware'].must_be_nil
      response.body.must_equal 'Hello from NoUseAction::Index'
    end
  end
end
