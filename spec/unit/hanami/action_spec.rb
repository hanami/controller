RSpec.describe Hanami::Action do
  describe '.configuration' do
    after do
      CallAction.configuration.reset!
    end

    it 'has the same defaults of Hanami::Controller' do
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

  describe '#call' do
    it 'calls an action' do
      response = CallAction.new.call({})

      expect(response[0]).to eq(201)
      expect(response[1]).to eq('Content-Type' => 'application/octet-stream; charset=utf-8', 'X-Custom' => 'OK')
      expect(response[2]).to eq(['Hi from TestAction!'])
    end

    describe 'when exception handling code is enabled' do
      it 'returns an HTTP 500 status code when an exception is raised' do
        response = ErrorCallAction.new.call({})

        expect(response[0]).to eq(500)
        expect(response[2]).to eq(['Internal Server Error'])
      end

      it 'handles inherited exception with specified method' do
        response = ErrorCallFromInheritedErrorClass.new.call({})

        expect(response[0]).to eq(501)
        expect(response[2]).to eq(['An inherited exception occurred!'])
      end

      it 'handles exception with specified method' do
        response = ErrorCallFromInheritedErrorClassStack.new.call({})

        expect(response[0]).to eq(501)
        expect(response[2]).to eq(['MyCustomError was thrown'])
      end

      it 'handles exception with specified method (symbol)' do
        response = ErrorCallWithSymbolMethodNameAsHandlerAction.new.call({})

        expect(response[0]).to eq(501)
        expect(response[2]).to eq(['Please go away!'])
      end

      it 'handles exception with specified method (string)' do
        response = ErrorCallWithStringMethodNameAsHandlerAction.new.call({})

        expect(response[0]).to eq(502)
        expect(response[2]).to eq(['StandardError'])
      end

      it 'handles exception with specified status code' do
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

    describe 'when exception handling code is disabled' do
      before do
        ErrorCallAction.configuration.handle_exceptions = false
      end

      after do
        ErrorCallAction.configuration.reset!
      end

      it 'should raise an actual exception' do
        expect { ErrorCallAction.new.call({}) }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#request' do
    it 'gets a Rack-like request object' do
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

  describe '#parsed_request_body' do
    it 'exposes the body of the request parsed by router body parsers' do
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
  end

  describe 'Method visibility' do
    before do
      @action = VisibilityAction.new
    end

    it 'x' do
      status, headers, body = @action.call({})

      expect(status).to be(201)

      expect(headers.fetch('X-Custom')).to eq('OK')
      expect(headers.fetch('Y-Custom')).to eq('YO')

      expect(body).to eq(['x'])
    end

    it 'has a public errors method' do
      expect(@action.public_methods).to include(:errors)
    end
  end
end
