require "hanami/devtools/unit"

RSpec.describe Hanami::Action do
  describe ".configuration" do
    after do
      CallAction.configuration.reset!
    end

    it "has the same defaults of Hanami::Controller" do
      expected = Hanami::Controller.configuration
      actual   = CallAction.configuration

      expect(actual.handle_exceptions).to eq(expected.handle_exceptions)
    end

    it "doesn't interfer with other action's configurations" do
      CallAction.configuration.handle_exceptions = false

      expect(Hanami::Controller.configuration.handle_exceptions).to be(true)
      expect(ErrorCallAction.configuration.handle_exceptions).to    be(true)
    end
  end

  describe "#call" do
    it "calls an action" do
      response = CallAction.new.call({})

      expect(response[0]).to eq(201)
      expect(response[1]).to eq('Content-Type' => 'application/octet-stream; charset=utf-8', 'X-Custom' => 'OK')
      expect(response[2]).to eq(['Hi from TestAction!'])
    end

    context "when exception handling code is enabled" do
      it "returns an HTTP 500 status code when an exception is raised" do
        response = ErrorCallAction.new.call({})

        expect(response[0]).to eq(500)
        expect(response[2]).to eq(['Internal Server Error'])
      end

      it "handles inherited exception with specified method" do
        response = ErrorCallFromInheritedErrorClass.new.call({})

        expect(response[0]).to eq(501)
        expect(response[2]).to eq(['An inherited exception occurred!'])
      end

      it "handles exception with specified method" do
        response = ErrorCallFromInheritedErrorClassStack.new.call({})

        expect(response[0]).to eq(501)
        expect(response[2]).to eq(['MyCustomError was thrown'])
      end

      it "handles exception with specified method (symbol)" do
        response = ErrorCallWithSymbolMethodNameAsHandlerAction.new.call({})

        expect(response[0]).to eq(501)
        expect(response[2]).to eq(['Please go away!'])
      end

      it "handles exception with specified method (string)" do
        response = ErrorCallWithStringMethodNameAsHandlerAction.new.call({})

        expect(response[0]).to eq(502)
        expect(response[2]).to eq(['StandardError'])
      end

      it "handles exception with specified status code" do
        response = ErrorCallWithSpecifiedStatusCodeAction.new.call({})

        expect(response[0]).to eq(422)
        expect(response[2]).to eq(['Unprocessable Entity'])
      end

      it "returns a successful response if the code and status aren't set" do
        response = ErrorCallWithUnsetStatusResponse.new.call({})

        expect(response[0]).to eq(200)
        expect(response[2]).to eq([])
      end
    end

    context "when exception handling code is disabled" do
      before do
        ErrorCallAction.configuration.handle_exceptions = false
      end

      after do
        ErrorCallAction.configuration.reset!
      end

      it "should raise an actual exception" do
        expect { ErrorCallAction.new.call({}) }.to raise_error(RuntimeError)
      end
    end

    context "when invoking the session method with sessions disabled" do
      before { MissingSessionAction.configuration.handle_exceptions = false }
      after { MissingSessionAction.configuration.reset! }

      it "raises an informative exception" do
        expected = Hanami::Controller::MissingSessionError
        expect { MissingSessionAction.new.call({}) }.to raise_error(expected, "To use `session', add `include Hanami::Action::Session`.")
      end
    end

    context "when invoking the flash method with sessions disabled" do
      before { MissingFlashAction.configuration.handle_exceptions = false }
      after { MissingFlashAction.configuration.reset! }

      it "raises an informative exception" do
        expected = Hanami::Controller::MissingSessionError
        expect { MissingFlashAction.new.call({}) }.to raise_error(expected, "To use `flash', add `include Hanami::Action::Session`.")
      end
    end
  end

  describe "#request" do
    it "gets a Rack-like request object" do
      action_class = Class.new do
        include Hanami::Action

        expose :req

        def call(_)
          @req = request
        end
      end

      action = action_class.new
      env = Rack::MockRequest.env_for('http://example.com/foo')
      action.call(env)

      request = action.req
      expect(request.path).to eq('/foo')
    end
  end

  describe "#parsed_request_body" do
    it "exposes the body of the request parsed by router body parsers", silence_deprecations: true do
      action_class = Class.new do
        include Hanami::Action

        expose :request_body

        def call(_)
          @request_body = parsed_request_body
        end
      end

      action = action_class.new
      env = Rack::MockRequest.env_for('http://example.com/foo',
                                      'router.parsed_body' => { 'a' => 'foo' })
      action.call(env)
      parsed_request_body = action.request_body
      expect(parsed_request_body).to eq('a' => 'foo')
    end

    it "shows deprecation message" do
      action_class = Class.new do
        include Hanami::Action

        expose :request_body

        def call(_)
          @request_body = parsed_request_body
        end
      end

      action = action_class.new
      env = Rack::MockRequest.env_for('http://example.com/foo',
                                      'router.parsed_body' => { 'a' => 'foo' })

      expect { action.call(env) }.to output(/#parsed_request_body is deprecated and it will be removed in future versions/).to_stderr
    end
  end

  describe "Method visibility" do
    let(:action) { VisibilityAction.new }

    it "ensures that protected and private methods can be safely invoked by developers" do
      status, headers, body = action.call({})

      expect(status).to be(201)

      expect(headers.fetch('X-Custom')).to eq('OK')
      expect(headers.fetch('Y-Custom')).to eq('YO')

      expect(body).to eq(['x'])
    end

    it "has a public errors method" do
      expect(action.public_methods).to include(:errors)
    end
  end
end
