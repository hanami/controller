require 'test_helper'
require 'hanami/router'

ErrorsRoutes = Hanami::Router.new do
  get '/without_message',         to: 'errors#without_message'
  get '/with_message',            to: 'errors#with_message'
  get '/with_custom_message',     to: 'errors#with_custom_message'
  get '/action_managed',          to: 'errors#action_managed'
  get '/action_managed_subclass', to: 'errors#action_managed_subclass'
  get '/framework_managed',       to: 'errors#framework_managed'
end

HandledException          = Class.new(StandardError)
FrameworkHandledException = Class.new(StandardError)
AuthException             = Class.new(StandardError)
CustomAuthException       = Class.new(StandardError) do
  def to_s
    "#{super} :("
  end
end

class HandledExceptionSubclass < HandledException; end

Hanami::Controller.configure do
  handle_exception FrameworkHandledException => 500
end

module Errors
  class WithoutMessage
    include Hanami::Action

    def call(params)
      raise AuthException
    end
  end

  class WithMessage
    include Hanami::Action

    def call(params)
      raise AuthException.new %q{you're not authorized to see this page!}
    end
  end

  class WithCustomMessage
    include Hanami::Action

    def call(params)
      raise CustomAuthException, 'plz go away!!'
    end
  end

  class ActionManaged
    include Hanami::Action
    handle_exception HandledException => 400

    def call(params)
      raise HandledException.new
    end
  end

  class ActionManagedSubclass
    include Hanami::Action
    handle_exception HandledException => 400

    def call(params)
      raise HandledExceptionSubclass.new
    end
  end

  class FrameworkManaged
    include Hanami::Action

    def call(params)
      raise FrameworkHandledException.new
    end
  end
end

Hanami::Controller.unload!

DisabledErrorsRoutes = Hanami::Router.new do
  get '/action_managed',    to: 'disabled_errors#action_managed'
  get '/framework_managed', to: 'disabled_errors#framework_managed'
end

Hanami::Controller.configure do
  handle_exceptions false
  handle_exception FrameworkHandledException => 500
end

module DisabledErrors
  class ActionManaged
    include Hanami::Action
    handle_exception HandledException => 400

    def call(params)
      raise HandledException.new
    end
  end

  class FrameworkManaged
    include Hanami::Action

    def call(params)
      raise FrameworkHandledException.new
    end
  end
end

Hanami::Controller.unload!

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

  it "doesn't dump exception in rack.errors if it's managed by an action" do
    response = @app.get('/action_managed')
    response.errors.must_be_empty
  end

  it "doesn't dump exception in rack.errors if it's managed by an action" do
    response = @app.get('/action_managed_subclass')
    response.errors.must_be_empty
  end

  it "doesn't dump exception in rack.errors if it's managed by the framework" do
    response = @app.get('/framework_managed')
    response.errors.must_be_empty
  end

  describe 'when exception management is disabled' do
    before do
      @app = Rack::MockRequest.new(DisabledErrorsRoutes)
    end

    it "dumps the exception in rack.errors even if it's managed by the action" do
      -> {
        response = @app.get('/action_managed')
        response.errors.wont_be_empty
      }.must_raise(HandledException)
    end

    it "dumps the exception in rack.errors even if it's managed by the framework" do
      -> {
        response = @app.get('/framework_managed')
        response.errors.wont_be_empty
      }.must_raise(FrameworkHandledException)
    end
  end
end
