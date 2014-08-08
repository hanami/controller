require 'test_helper'

describe Lotus::Action do
  describe '.configuration' do
    after do
      CallAction.configuration.reset!
    end

    it 'has the same defaults of Lotus::Controller' do
      expected = Lotus::Controller.configuration
      actual   = CallAction.configuration

      actual.handle_exceptions.must_equal(expected.handle_exceptions)
    end

    it "doesn't interfer with other action's configurations" do
      CallAction.configuration.handle_exceptions = false

      Lotus::Controller.configuration.handle_exceptions.must_equal(true)
      ErrorCallAction.configuration.handle_exceptions.must_equal(true)
    end
  end

  describe '#call' do
    it 'calls an action' do
      response = CallAction.new.call({})

      response[0].must_equal 201
      response[1].must_equal({'Content-Type' => 'application/octet-stream', 'X-Custom' => 'OK'})
      response[2].must_equal ['Hi from TestAction!']
    end

    it 'returns an HTTP 500 status code when an exception is raised' do
      response = ErrorCallAction.new.call({})

      response[0].must_equal 500
      response[2].must_equal ['Internal Server Error']
    end

    it 'exposes validation errors' do
      action     = ParamsValidationAction.new
      code, _, _ = action.call({})

      code.must_equal 400
      action.errors.for(:email).must_include Lotus::Validations::Error.new(:email, :presence, true, nil)
    end

    describe 'when exception handling code is disabled' do
      before do
        ErrorCallAction.configuration.handle_exceptions = false
      end

      after do
        ErrorCallAction.configuration.reset!
      end

      it 'should raise an actual exception' do
        proc {
          ErrorCallAction.new.call({})
        }.must_raise RuntimeError
      end
    end
  end

  describe '#expose' do
    it 'creates a getter for the given ivar' do
      action = ExposeAction.new

      response = action.call({})
      response[0].must_equal 200

      action.exposures.fetch(:film).must_equal '400 ASA'
      action.exposures.fetch(:time).must_equal nil
    end
  end
end
