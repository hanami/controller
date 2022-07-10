require 'hanami/router'

class ExceptionHandler
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue => e
    [500, {}, [e.message]]
  end
end

UnhandledException                  = Class.new(StandardError)
UnhandledExceptionWithMessage       = Class.new(StandardError)
UnhandledExceptionWithCustomMessage = Class.new(StandardError) do
  def to_s
    "#{super} :("
  end
end

HandledException                      = Class.new(StandardError)
HandledExceptionSubclass              = Class.new(HandledException)
ConfigurationHandledException         = Class.new(StandardError)
ConfigurationHandledExceptionSubclass = Class.new(ConfigurationHandledException)

module Errors
  # Unhandled
  class WithoutMessage < Hanami::Action
    def call(*)
      raise UnhandledException
    end
  end

  class WithMessage < Hanami::Action
    def call(*)
      raise UnhandledExceptionWithMessage, "boom"
    end
  end

  class WithCustomMessage < Hanami::Action
    def call(*)
      raise UnhandledExceptionWithCustomMessage, "nope"
    end
  end

  # Handled
  class ActionHandled < Hanami::Action
    config.handle_exception HandledException => 400

    def call(*)
      raise HandledException
    end
  end

  class ActionHandledSubclass < Hanami::Action
    config.handle_exception HandledException => 400

    def call(*)
      raise HandledExceptionSubclass
    end
  end

  class ConfigurationHandled < Hanami::Action
    config.handle_exception ConfigurationHandledException => 500

    def call(*)
      raise ConfigurationHandledException
    end
  end

  class ConfigurationHandledSubclass < Hanami::Action
    config.handle_exception ConfigurationHandledException => 500

    def call(*)
      raise ConfigurationHandledExceptionSubclass
    end
  end

  class Application
    def initialize
      routes = Hanami::Router.new do
        get '/without_message',     to: Errors::WithoutMessage.new
        get '/with_message',        to: Errors::WithMessage.new
        get '/with_custom_message', to: Errors::WithCustomMessage.new

        get '/action_handled',                 to: Errors::ActionHandled.new
        get '/action_handled_subclass',        to: Errors::ActionHandledSubclass.new
        get '/configuration_handled',          to: Errors::ConfigurationHandled.new
        get '/configuration_handled_subclass', to: Errors::ConfigurationHandledSubclass.new
      end

      @app = Rack::Builder.new do
        use Rack::Lint
        use ExceptionHandler
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

  context "unhandled exceptions" do
    it "adds exception to rack.errors" do
      response = app.get("/without_message")
      expect(response.errors).to include("UnhandledException")
    end

    it "adds exception message to rack.errors" do
      response = app.get("/with_message")
      expect(response.errors).to include("UnhandledExceptionWithMessage: boom\n")
    end

    it "uses exception string representation" do
      response = app.get("/with_custom_message")
      expect(response.errors).to include("UnhandledExceptionWithCustomMessage: nope :(\n")
    end
  end

  context "handled exceptions" do
    it "doesn't dump exception in rack.errors if it's handled by an action" do
      response = app.get("/action_handled")
      expect(response.errors).to be_empty
    end

    it "doesn't dump exception in rack.errors if its superclass exception is handled by an action" do
      response = app.get("/action_handled_subclass")
      expect(response.errors).to be_empty
    end

    xit "doesn't dump exception in rack.errors if it's handled by the configuration" do
      response = app.get("/configuration_handled")
      expect(response.errors).to be_empty
    end

    xit "doesn't dump exception in rack.errors if its superclass is handled by the configuration" do
      response = app.get("/configuration_handled_subclass")
      expect(response.errors).to be_empty
    end
  end
end
