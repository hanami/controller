require 'test_helper'
require 'lotus/router'

ErrorsRoutes = Lotus::Router.new do
  get '/without_message', to: 'errors#without_message'
  get '/with_message',    to: 'errors#with_message'
end

AuthException = Class.new(StandardError)

class ErrorsController
  include Lotus::Controller

  action 'WithoutMessage' do
    def call(params)
      raise AuthException
    end
  end

  action 'WithMessage' do
    def call(params)
      raise AuthException, %q{AuthException: you're not authorized to see this page!}
    end
  end
end

describe 'Reference exception in rack.errors' do
  before do
    @app = Rack::MockRequest.new(ErrorsRoutes)
  end

  it 'adds exception to rack.errors' do
    response = @app.get('/without_message')
    response.errors.must_equal "AuthException\n"
  end

  it 'adds exception message to rack.errors' do
    response = @app.get('/with_message')
    response.errors.must_equal "AuthException: you're not authorized to see this page!\n"
  end
end