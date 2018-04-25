RSpec.describe Hanami::Action do
  describe "#initialize" do
    it "instantiate a frozen action" do
      action = CallAction.new(configuration: configuration)
      expect(action).to be_frozen
    end
  end

  describe "#call" do
    it "calls an action" do
      response = CallAction.new(configuration: configuration).call({})

      expect(response.status).to  eq(201)
      expect(response.headers).to eq("Content-Length" => "19", "Content-Type" => "application/octet-stream; charset=utf-8", "X-Custom" => "OK")
      expect(response.body).to    eq(["Hi from TestAction!"])
    end

    context "when an exception isn't handled" do
      it "should raise an actual exception" do
        expect { UncheckedErrorCallAction.new(configuration: configuration).call({}) }.to raise_error(RuntimeError)
      end
    end

    context "when an exception is handled" do
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

    context "when invoking the session method with sessions disabled" do
      it "raises an informative exception" do
        expected = Hanami::Controller::MissingSessionError
        expect { MissingSessionAction.new(configuration: configuration).call({}) }.to raise_error(expected, "To use `session', add `include Hanami::Action::Session`.")
      end
    end

    context "when invoking the flash method with sessions disabled" do
      it "raises an informative exception" do
        expected = Hanami::Controller::MissingSessionError
        expect { MissingFlashAction.new(configuration: configuration).call({}) }.to raise_error(expected, "To use `flash', add `include Hanami::Action::Session`.")
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

  describe "Method visibility" do
    let(:action) { VisibilityAction.new(configuration: configuration) }

    it "ensures that protected and private methods can be safely invoked by developers" do
      response = action.call({})

      expect(response.status).to be(201)

      expect(response.headers.fetch("X-Custom")).to eq("OK")
      expect(response.headers.fetch("Y-Custom")).to eq("YO")

      expect(response.body).to eq(["x"])
    end
  end
end
