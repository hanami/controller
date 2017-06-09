require 'hanami/router'

HandledException          = Class.new(StandardError)
FrameworkHandledException = Class.new(StandardError)
AuthException             = Class.new(StandardError)
CustomAuthException       = Class.new(StandardError) do
  def to_s
    "#{super} :("
  end
end

class HandledExceptionSubclass < HandledException; end

module Errors
  class WithoutMessage
    include Hanami::Action

    def call(_params)
      raise AuthException
    end
  end

  class WithMessage
    include Hanami::Action

    def call(_params)
      raise AuthException, "you're not authorized to see this page!"
    end
  end

  class WithCustomMessage
    include Hanami::Action

    def call(_params)
      raise CustomAuthException, 'plz go away!!'
    end
  end

  class ActionManaged
    include Hanami::Action
    handle_exception HandledException => 400

    def call(_params)
      raise HandledException
    end
  end

  class ActionManagedSubclass
    include Hanami::Action
    handle_exception HandledException => 400

    def call(_params)
      raise HandledExceptionSubclass
    end
  end

  class FrameworkManaged
    include Hanami::Action

    def call(_params)
      raise FrameworkHandledException
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new do |config|
        config.handle_exception FrameworkHandledException => 500
      end
      resolver = EndpointResolver.new(configuration: configuration)

      routes = Hanami::Router.new(resolver: resolver) do
        get '/without_message',         to: 'errors#without_message'
        get '/with_message',            to: 'errors#with_message'
        get '/with_custom_message',     to: 'errors#with_custom_message'
        get '/action_managed',          to: 'errors#action_managed'
        get '/action_managed_subclass', to: 'errors#action_managed_subclass'
        get '/framework_managed',       to: 'errors#framework_managed'
      end

      @app = Rack::Builder.new do
        use Rack::Lint
        run routes
      end.to_app
    end

    def call(env)
      @app.call(env)
    end
  end
end

module DisabledErrors
  class ActionManaged
    include Hanami::Action
    handle_exception HandledException => 400

    def call(_params)
      raise HandledException
    end
  end

  class FrameworkManaged
    include Hanami::Action

    def call(_params)
      raise FrameworkHandledException
    end
  end

  class Application
    def initialize
      configuration = Hanami::Controller::Configuration.new do |config|
        config.handle_exceptions = false
        config.handle_exception FrameworkHandledException => 500
      end

      resolver = EndpointResolver.new(configuration: configuration)

      routes = Hanami::Router.new(resolver: resolver) do
        get '/action_managed',    to: 'disabled_errors#action_managed'
        get '/framework_managed', to: 'disabled_errors#framework_managed'
      end

      @app = Rack::Builder.new do
        use Rack::Lint
        run routes
      end.to_app
    end

    def call(env)
      @app.call(env)
    end
  end
end

RSpec.describe 'Reference exception in "rack.errors"' do
  let(:app) { Rack::MockRequest.new(Errors::Application.new) }

  it "adds exception to rack.errors" do
    response = app.get("/without_message")
    expect(response.errors).to include("AuthException")
  end

  it "adds exception message to rack.errors" do
    response = app.get("/with_message")
    expect(response.errors).to include("AuthException: you're not authorized to see this page!\n")
  end

  it "uses exception string representation" do
    response = app.get("/with_custom_message")
    expect(response.errors).to include("CustomAuthException: plz go away!! :(\n")
  end

  it "doesn't dump exception in rack.errors if it's managed by an action" do
    response = app.get("/action_managed")
    expect(response.errors).to be_empty
  end

  it "doesn't dump exception in rack.errors if it's managed by an action" do
    response = app.get("/action_managed_subclass")
    expect(response.errors).to be_empty
  end

  it "doesn't dump exception in rack.errors if it's managed by the framework" do
    response = app.get("/framework_managed")
    expect(response.errors).to be_empty
  end

  context "when exception management is disabled" do
    let(:app) { Rack::MockRequest.new(DisabledErrors::Application.new) }

    it "dumps the exception in rack.errors even if it's managed by the action" do
      expect do
        response = app.get("/action_managed")
        response.errors.wont_be_empty
      end.to raise_error(HandledException)
    end

    it "dumps the exception in rack.errors even if it's managed by the framework" do
      expect do
        response = app.get("/framework_managed")
        response.errors.wont_be_empty
      end.to raise_error(FrameworkHandledException)
    end
  end
end
