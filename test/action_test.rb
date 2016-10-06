require 'test_helper'

describe Hanami::Action do
  describe '.configuration' do
    it 'copies configuration from module' do
      expected = Test.configuration
      actual   = Test::CallAction.configuration

      actual.must_equal(expected)
    end

    it "doesn't interfer with other action's configurations" do
      Test.configuration.handle_exceptions.must_equal(true)
      Test.configuration.handled_exceptions.must_equal({})

      Test::CallAction.configuration.handle_exceptions.must_equal(true)
      Test::CallAction.configuration.handled_exceptions.must_equal({})

      Test::HandleExceptions.configuration.handle_exceptions.must_equal(false)
      Test::HandleExceptions.configuration.handled_exceptions.must_equal(StandardError => 500)
    end
  end

  describe '#call' do
    it 'calls an action' do
      response = Test::CallAction.new.call({})

      response[0].must_equal 201
      response[1].must_equal('Content-Type' => 'application/octet-stream; charset=utf-8', 'X-Custom' => 'OK')
      response[2].must_equal ['Hi from TestAction!']
    end

    describe 'when exception handling code is enabled' do
      it 'returns an HTTP 500 status code when an exception is raised' do
        response = ErrorCallAction.new.call({})

        response[0].must_equal 500
        response[2].must_equal ['Internal Server Error']
      end

      it 'handles inherited exception with specified method' do
        response = ErrorCallFromInheritedErrorClass.new.call({})

        response[0].must_equal 501
        response[2].must_equal ['An inherited exception occurred!']
      end

      it 'handles exception with specified method' do
        response = ErrorCallFromInheritedErrorClassStack.new.call({})

        response[0].must_equal 501
        response[2].must_equal ['MyCustomError was thrown']
      end

      it 'handles exception with specified method (symbol)' do
        response = ErrorCallWithSymbolMethodNameAsHandlerAction.new.call({})

        response[0].must_equal 501
        response[2].must_equal ['Please go away!']
      end

      it 'handles exception with specified method (string)' do
        response = ErrorCallWithStringMethodNameAsHandlerAction.new.call({})

        response[0].must_equal 502
        response[2].must_equal ['StandardError']
      end

      it 'handles exception with specified status code' do
        response = ErrorCallWithSpecifiedStatusCodeAction.new.call({})

        response[0].must_equal 422
        response[2].must_equal ['Unprocessable Entity']
      end

      it "returns a successful response if the code and status aren't set" do
        response = ErrorCallWithUnsetStatusResponse.new.call({})

        response[0].must_equal 200
        response[2].must_equal []
      end
    end

    describe 'when exception handling code is disabled' do
      before do
        @action = ErrorCallAction.new(configuration: { handle_exceptions: false })
      end

      it 'should raise an actual exception' do
        lambda do
          @action.call({})
        end.must_raise RuntimeError
      end
    end
  end

  describe '#request' do
    it 'gets a Rack-like request object' do
      klass = nil

      Module.new {
        include Hanami::Controller

        klass = Class.new do
          include Hanami::Action
          expose :req

          def call(_params)
            @req = request
          end
        end
      }

      action = klass.new
      env = Rack::MockRequest.env_for('http://example.com/foo')
      action.call(env)

      request = action.req
      request.path.must_equal('/foo')
    end
  end

  describe '#parsed_request_body' do
    it 'exposes the body of the request parsed by router body parsers' do
      action_class = Class.new do
        include Hanami::Action

        expose :request_body

        def call(params)
          @request_body = parsed_request_body
        end
      end

      action = action_class.new
      env = Rack::MockRequest.env_for('http://example.com/foo',
                                      'router.parsed_body' => { 'a' => 'foo' })
      action.call(env)
      parsed_request_body = action.request_body
      parsed_request_body.must_equal({ 'a' => 'foo' })
    end
  end
end
