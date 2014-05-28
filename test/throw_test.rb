require 'test_helper'

describe Lotus::Action do
  before do
    Lotus::Controller.configuration.reset!
    UnhandledExceptionAction.configuration.reset!
  end

  describe '.handle_exception' do
    it 'handle an exception with the given status' do
      response = HandledExceptionAction.new.call({})

      response[0].must_equal 404
    end

    it "returns a 500 if an action isn't handled" do
      response = UnhandledExceptionAction.new.call({})

      response[0].must_equal 500
    end

    describe 'with global handled exceptions' do
      before do
        class DomainLogicException < StandardError
        end

        Lotus::Controller.configure do
          handle_exception DomainLogicException => 400
        end

        class GlobalHandledExceptionAction
          include Lotus::Action

          def call(params)
            raise DomainLogicException.new
          end
        end
      end

      after do
        Object.send(:remove_const, :DomainLogicException)
        Object.send(:remove_const, :GlobalHandledExceptionAction)

        Lotus::Controller.configuration.reset!
      end

      it 'handles raised exception' do
        response = GlobalHandledExceptionAction.new.call({})

        response[0].must_equal 400
      end
    end
  end

  describe '#throw' do
    before do
      ThrowCodeAction.configuration.reset!
    end

    HTTP_TEST_STATUSES.each do |code, body|
      it "throws an HTTP status code: #{ code }" do
        response = ThrowCodeAction.new.call({ status: code })

        response[0].must_equal  code
        response[2].must_equal [body]
      end
    end

    it 'throws the code as it is, when not recognized' do
      response = ThrowCodeAction.new.call({ status: 2131231 })

      response[0].must_equal 500
      response[2].must_equal ['Internal Server Error']
    end

    it 'stops execution of before filters (method)' do
      response = ThrowBeforeMethodAction.new.call({})

      response[0].must_equal 401
      response[2].must_equal ['Unauthorized']
    end

    it 'stops execution of before filters (block)' do
      response = ThrowBeforeBlockAction.new.call({})

      response[0].must_equal 401
      response[2].must_equal ['Unauthorized']
    end

    it 'stops execution of after filters (method)' do
      response = ThrowAfterMethodAction.new.call({})

      response[0].must_equal 408
      response[2].must_equal ['Request Timeout']
    end

    it 'stops execution of after filters (block)' do
      response = ThrowAfterBlockAction.new.call({})

      response[0].must_equal 408
      response[2].must_equal ['Request Timeout']
    end
  end

  describe 'using Kernel#throw in an action' do
    it 'should work' do
      response = CatchAndThrowSymbolAction.new.call({})

      response[0].must_equal 200
    end
  end
end
