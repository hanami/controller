RSpec.describe Hanami::Action do
  # FIXME: resume the "doesn't interfer" spec
  #
  # describe ".configuration" do
  #   after do
  #     CallAction.configuration.reset!
  #   end

  #   it "has the same defaults of Hanami::Controller" do
  #     expected = Hanami::Controller.configuration
  #     actual   = CallAction.configuration

  #     expect(actual.handle_exceptions).to eq(expected.handle_exceptions)
  #   end

  #   it "doesn't interfer with other action's configurations" do
  #     CallAction.configuration.handle_exceptions = false

  #     expect(Hanami::Controller.configuration.handle_exceptions).to be(true)
  #     expect(ErrorCallAction.configuration.handle_exceptions).to    be(true)
  #   end
  # end

  describe "#call" do
    it "calls an action" do
      response = CallAction.new(configuration: configuration).call({})

      expect(response.status).to  eq(201)
      expect(response.headers).to eq("Content-Length" => "19", "Content-Type" => "application/octet-stream; charset=utf-8", "X-Custom" => "OK")
      expect(response.body).to    eq(["Hi from TestAction!"])
    end

    context "when exception handling code is enabled" do
      it "returns an HTTP 500 status code when an exception is raised" do
        response = ErrorCallAction.new(configuration: configuration).call({})

        expect(response.status).to eq(500)
        expect(response.body).to   eq(["Internal Server Error"])
      end

      it "handles inherited exception with specified method" do
        response = ErrorCallFromInheritedErrorClass.new(configuration: configuration).call({})

        expect(response.status).to eq(501)
        expect(response.body).to   eq(["An inherited exception occurred!"])
      end

      it "handles exception with specified method" do
        response = ErrorCallFromInheritedErrorClassStack.new(configuration: configuration).call({})

        expect(response.status).to eq(501)
        expect(response.body).to   eq(["MyCustomError was thrown"])
      end

      it "handles exception with specified method (symbol)" do
        response = ErrorCallWithSymbolMethodNameAsHandlerAction.new(configuration: configuration).call({})

        expect(response.status).to eq(501)
        expect(response.body).to   eq(["Please go away!"])
      end

      it "handles exception with specified method (string)" do
        response = ErrorCallWithStringMethodNameAsHandlerAction.new(configuration: configuration).call({})

        expect(response.status).to eq(502)
        expect(response.body).to   eq(["StandardError"])
      end

      it "handles exception with specified status code" do
        response = ErrorCallWithSpecifiedStatusCodeAction.new(configuration: configuration).call({})

        expect(response.status).to eq(422)
        expect(response.body).to   eq(["Unprocessable Entity"])
      end

      it "returns a successful response if the code and status aren't set" do
        response = ErrorCallWithUnsetStatusResponse.new(configuration: configuration).call({})

        expect(response.status).to eq(200)
        expect(response.body).to   eq([])
      end
    end

    context "when exception handling code is disabled" do
      let(:configuration) do
        Hanami::Controller::Configuration.new do |config|
          config.handle_exceptions = false
        end
      end

      it "should raise an actual exception" do
        expect { ErrorCallAction.new(configuration: configuration).call({}) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#request" do
    it "gets a Rack-like request object" do
      action_class = Class.new(Hanami::Action) do
        def call(req, res)
          res[:request] = req
        end
      end

      action = action_class.new(configuration: configuration)
      env = Rack::MockRequest.env_for('http://example.com/foo')
      response = action.call(env)

      expect(response[:request].path).to eq('/foo')
    end
  end

  describe "#parsed_request_body" do
    it "exposes the body of the request parsed by router body parsers" do
      action_class = Class.new(Hanami::Action) do
        def call(*, res)
          res[:parsed_request_body] = parsed_request_body
        end
      end

      action = action_class.new(configuration: configuration)
      env = Rack::MockRequest.env_for('http://example.com/foo',
                                      'router.parsed_body' => { 'a' => 'foo' })
      response = action.call(env)
      expect(response[:parsed_request_body]).to eq('a' => 'foo')
    end
  end

  describe "Method visibility" do
    let(:action) { VisibilityAction.new(configuration: configuration) }

    it "ensures that protected and private methods can be safely invoked by developers" do
      response = action.call({})

      expect(response.status).to be(201)

      expect(response.headers.fetch("X-Custom")).to eq("OK")
      expect(response.headers.fetch("Y-Custom")).to eq("YO")

      expect(response.body).to eq(["x"])
    end

    it "has a public errors method" do
      expect(action.public_methods).to include(:errors)
    end
  end
end
