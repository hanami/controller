require 'test_helper'
require 'lotus/router'

ErrorsRoutes = Lotus::Router.new do
  get '/without_message',     to: 'errors#without_message'
  get '/with_message',        to: 'errors#with_message'
  get '/with_custom_message', to: 'errors#with_custom_message'
end

AuthException       = Class.new(StandardError)
CustomAuthException = Class.new(StandardError) do
  def to_s
    "#{super} :("
  end
end

module Errors
  include Lotus::Controller

  class WithoutMessage
    include Lotus::Action

    def call(params)
      raise AuthException
    end
  end

  class WithMessage
    include Lotus::Action

    def call(params)
      raise AuthException.new %q{you're not authorized to see this page!}
    end
  end

  class WithCustomMessage
    include Lotus::Action

    def call(params)
      raise CustomAuthException, 'plz go away!!'
    end
  end
end

describe 'Reference exception in rack.errors' do
  before do
    @app = Rack::MockRequest.new(ErrorsRoutes)
  end

  it 'adds exception to rack.errors' do
    response = @app.get('/without_message')
    response.errors.must_include "AuthException"
  end

  it 'adds exception message to rack.errors' do
    response = @app.get('/with_message')
    response.errors.must_include "AuthException: you're not authorized to see this page!\n"
  end

  it 'uses exception string representation' do
    response = @app.get('/with_custom_message')
    response.errors.must_include "CustomAuthException: plz go away!! :(\n"
  end
end
